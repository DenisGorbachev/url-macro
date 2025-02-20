#!/usr/bin/env -S deno run --allow-write --allow-read --allow-run=bash,git,cargo --allow-net=docs.rs:443 --allow-env --allow-sys --no-lock

// NOTE: Pin the versions of the packages because the script runs without a lock file
import * as zx from "npm:zx@8.3.2"
import { z, ZodSchema, ZodTypeDef } from "https://deno.land/x/zod@v3.23.8/mod.ts"
import { assert, assertEquals } from "jsr:@std/assert@1.0.0"
import { toSnakeCase } from "jsr:@std/text@1.0.10"
import { parseArgs } from "jsr:@std/cli@1.0.13"

export const args = parseArgs(Deno.args, {
    string: ["output"],
    alias: {
        output: "o",
    },
})

const CargoTomlSchema = z.object({
    package: z.object({
        name: z.string().min(1),
        description: z.string().min(1),
        repository: z.string().url().min(1),
        metadata: z.object({
            details: z.object({
                title: z.string().min(1).optional(),
                tagline: z.string().optional(),
                summary: z.string().optional(),
                readme: z.object({
                   generate: z.boolean().default(true)
                }).default({}),
                peers: z.array(z.string()).default([]).describe("Packages that should be installed alongside this package"),
            }).default({}),
        }).default({}),
    }),
})

type CargoToml = z.infer<typeof CargoTomlSchema>

const CargoMetadataSchema = z.object({
    packages: z.array(z.object({
        name: z.string(),
        source: z.string().nullable(),
        targets: z.array(z.object({
            name: z.string(),
            kind: z.array(z.string()),
        })),
    })),
})

type CargoMetadata = z.infer<typeof CargoMetadataSchema>

const RepoSchema = z.object({
    url: z.string().url(),
})

type Repo = z.infer<typeof RepoSchema>

const BadgeSchema = z.object({
    name: z.string().min(1),
    image: z.string().url(),
    url: z.string().url(),
})

type Badge = z.infer<typeof BadgeSchema>

const badge = (name: string, image: string, url: string): Badge => BadgeSchema.parse({ name, url, image })

const SectionSchema = z.object({
    title: z.string().min(1),
    body: z.string(),
})

type Section = z.infer<typeof SectionSchema>

const section = (title: string, body: string): Section => SectionSchema.parse({ title, body })

const pushSection = (sections: Section[], title: string, body: string) => sections.push(section(title, body))

// Nested sections not supported
const renderSection = ({ title, body }: Section) => `## ${title}\n\n${body}`

const renderNonEmptySections = (sections: Section[]) => sections.filter((s) => s.body).map(renderSection).join("\n\n")

const stub = <T>(message = "Implement me"): T => {
    throw new Error(message)
}

const dirname = import.meta.dirname
if (!dirname) throw new Error("Cannot determine the current script dirname")

const $ = zx.$({ cwd: dirname })

// deno-lint-ignore no-explicit-any
const parse = <Output = any, Def extends ZodTypeDef = ZodTypeDef, Input = Output>(schema: ZodSchema<Output, Def, Input>, input: zx.ProcessOutput) => schema.parse(JSON.parse(input.stdout))
const nail = (str: string) => {
    const spacesAtStart = str.match(/^\n(\s+)/)
    if (spacesAtStart?.[1]) {
        return str.replace(new RegExp(`^[^\\S\r\n]{0,${spacesAtStart[1].length}}`, "gm"), "")
    } else {
        return str
    }
}

const cargoTomlPromise = $`yj -t < Cargo.toml`;
const cargoMetadataPromise = $`cargo metadata --format-version 1`;
const ghRepoPromise = $`gh repo view --json url`

const theCargoToml: CargoToml = parse(CargoTomlSchema, await cargoTomlPromise)
const theCargoMetadata: CargoMetadata = parse(CargoMetadataSchema, await cargoMetadataPromise)
const { package: { name, description, metadata: { details: {title: titleExplicit, peers, readme: {generate}} } } } = theCargoToml

// If README generation is manually disabled in the Cargo.toml, just exit successfully
if (!generate) {
    Deno.exit(0)
}

const title = titleExplicit || description
const _libTargetName = toSnakeCase(name)
const thePackageMetadata = theCargoMetadata.packages.find((p) => p.name == name)
assert(thePackageMetadata, "Could not find package metadata")
const primaryTarget = thePackageMetadata.targets[0]
assert(primaryTarget, "Could not find package primary target")
const primaryBinTarget = thePackageMetadata.targets.find((t) => t.name == name && t.kind.includes("bin"))
// NOTE: primaryTarget may be equal to primaryBinTarget
const primaryTargets = [primaryTarget, primaryBinTarget]
const secondaryTargets = thePackageMetadata.targets.filter((t) => !primaryTargets.includes(t))
const secondaryBinTargets = secondaryTargets.filter((t) => t.kind.includes("bin"))
const docsUrl = `https://docs.rs/${name}`
const doc2ReadmeTemplate = `
{{ readme }}

{%- if links != "" %}
  {{ links }}
{%- endif -%}
`.trimStart()
const doc2readmeRender = async (target: string) => {
    const templatePath = await Deno.makeTempFile({
        prefix: "README",
        suffix: "jl",
    })
    await Deno.writeTextFile(
        templatePath,
        doc2ReadmeTemplate,
    )
    return $`cargo doc2readme --template ${templatePath} --target-name ${target} --out -`
}

// launch multiple promises in parallel
const doc2ReadmePromise = doc2readmeRender(primaryTarget.name)
const docsUrlPromise = fetch(docsUrl, { method: "HEAD" })
const helpPromise = primaryBinTarget ? $`cargo run --quiet --bin ${primaryBinTarget.name} -- --help` : undefined

const doc = await doc2ReadmePromise
const docStr = doc.stdout.trim()

const repo: Repo = parse(RepoSchema, await ghRepoPromise)
assertEquals(repo.url, theCargoToml.package.repository)

const docsUrlHead = await docsUrlPromise
const docsUrlIs200 = docsUrlHead.status === 200

const badges: Badge[] = [
    badge("Build", `${repo.url}/actions/workflows/ci.yml/badge.svg`, repo.url),
]
if (docsUrlIs200) {
    badges.push(badge("Documentation", `https://docs.rs/${name}/badge.svg`, docsUrl))
}
const badgesStr = badges.map(({ name, image, url }) => `[![${name}](${image})](${url})`).join("\n")

const renderMarkdownList = (items: string[]) => items.map((bin) => `* ${bin}`).join("\n")
const renderShellCode = (code: string) => `\`\`\`shell\n${code}\n\`\`\``

const titleSectionBodyParts = [
    badgesStr,
    docStr,
].filter((s) => s.length)
const titleSectionBody = titleSectionBodyParts.join("\n\n")

const sections: Section[] = []
// NOTE: We need to use the package name (not the target name) in cargo commands
const installationSectionBodyParts = []
const installationSectionUseExpandedFormat = primaryBinTarget && primaryTarget !== primaryBinTarget
if (primaryBinTarget) {
    const cmd = renderShellCode(`cargo install --locked ${name}`)
    const text = installationSectionUseExpandedFormat ? `Install as executable:\n\n${cmd}` : cmd
    installationSectionBodyParts.push(text)
}
if (primaryTarget !== primaryBinTarget) {
    const cmd = renderShellCode(`cargo add ${[name, ...peers].join(" ")}`)
    const text = installationSectionUseExpandedFormat ? `Install as library dependency in your package:\n\n${cmd}` : cmd
    installationSectionBodyParts.push(text)
}
pushSection(sections, "Installation", installationSectionBodyParts.join("\n\n"))
if (helpPromise) {
    const help = await helpPromise
    pushSection(sections, "Usage", renderShellCode(help.stdout.trim()))
}
if (secondaryBinTargets.length) {
    const secondaryBinTargetsNames = secondaryBinTargets.map((t) => t.name)
    pushSection(sections, "Additional binaries", renderMarkdownList(secondaryBinTargetsNames.map((bin) => `\`${bin}\``)))
}
pushSection(sections, "Gratitude", `Like the project? [⭐ Star this repo](${repo.url}) on GitHub!`)
pushSection(
    sections,
    "License",
    `
[Apache License 2.0](LICENSE-APACHE) or [MIT License](LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this crate by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
`.trim(),
)

const body = renderNonEmptySections(sections)

const content = `
<!-- DO NOT EDIT -->
<!-- This file is automatically generated by README.ts. -->
<!-- Edit README.ts if you want to make changes. -->

# ${title}

${titleSectionBody}

${body}`.trim()

if (args.output) {
    await Deno.writeTextFile(args.output, content + "\n")
} else {
    console.info(content)
}
