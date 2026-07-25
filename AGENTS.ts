#!/usr/bin/env -S deno run --node-modules-dir=false --allow-read --allow-write --allow-run --no-lock

import { compare, parse } from "jsr:@std/semver@1.0.0"
import { stringify } from "jsr:@libs/xml@7.0.3"
import remarkHeadingShift from "npm:remark-heading-shift@1.1.2"
import remarkParse from "npm:remark-parse@11.0.0"
import remarkStringify from "npm:remark-stringify@11.0.0"
import { unified } from "npm:unified@11.0.5"
import { basename, dirname, extname, fromFileUrl, join, relative } from "jsr:@std/path@1.1.4"

const rootUrl = new URL(".", import.meta.url)
const rootPath = fromFileUrl(rootUrl)
const sourcePath = fromFileUrl(import.meta.url)
const decoder = new TextDecoder()

const isMarkdownPath = (path: string) => path.toLowerCase().endsWith(".md")

const resolvePath = (path: string) => new URL(path, rootUrl)

const fileExists = async (path: string) => {
  try {
    await Deno.stat(resolvePath(path))
    return true
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) return false
    throw error
  }
}

const shiftHeadings = async (markdown: string) => {
  const file = await unified()
    .use(remarkParse)
    .use(remarkHeadingShift, 1)
    .use(remarkStringify)
    .process(markdown)
  return String(file).trimEnd()
}

const renderCodeFile = (path: string, contents: string) => {
  const identifier = getLanguageIdentifier(path)
  const trimmed = contents.trimEnd()
  const fence = getFence(trimmed)
  const fenced = `${fence}${identifier}\n${trimmed}\n${fence}`
  return [`### ${path}`, fenced].join("\n\n")
}

const getFence = (contents: string) => {
  const matches = contents.match(/`+/g) ?? []
  const max = matches.reduce((current, match) => Math.max(current, match.length), 0)
  return "`".repeat(Math.max(3, max + 1))
}

const getLanguageIdentifier = (path: string) => {
  const extension = extname(path)
  switch (extension) {
    case ".conf":
      return "text"
    case ".ts":
      return "typescript"
    case ".rs":
      return "rust"
    case ".xml":
      return "xml"
    case ".toml":
      return "toml"
    default:
      throw new Error(`Could not get a language identifier for extension: ${extension}`)
  }
}

export const renderXmlFile = (path: string, contents: string) =>
  stringify(
    {
      file: {
        path,
        contents: "\n" + contents,
      },
    },
    {
      format: {
        indent: "",
        breakline: 0,
      },
    },
  ).trimEnd()

const includeFile = async (path: string) => {
  return await renderFileContents(path, await Deno.readTextFile(resolvePath(path)))
}

const renderFileContents = async (path: string, contents: string, pathToRender: string = path) => isMarkdownPath(path) ? await shiftHeadings(contents) : renderCodeFile(pathToRender, contents)

export const runAgentDocsList = async (): Promise<string[]> => {
  const command = new Deno.Command("mise", {
    args: ["run", "agent:docs:list"],
    stdout: "piped",
    stderr: "inherit",
    cwd: fromFileUrl(rootUrl),
  })
  const output = await command.output()
  const stdout = decoder.decode(output.stdout).trimEnd()
  return stdout ? stdout.split(/\r?\n/).filter((line) => line.length > 0) : []
}

export const includeAgentDocs = async () => {
  const files = await runAgentDocsList()
  if (!files.length) return ""
  return `# Extra docs

Read the extra docs from the list below if they are relevant to your current task:

${files.map((file) => `* ${file}`).join("\n")}`.trim()
}

type CargoMetadata = {
  packages: CargoPackage[]
  resolve: {
    nodes: {
      id: string
      deps: { name: string; pkg: string }[]
    }[]
  } | null
  workspace_members: string[]
  workspace_root: string
}

type CargoPackage = {
  id: string
  name: string
  version: string
  manifest_path: string
}

const cargoMetadataPromise = (async (): Promise<CargoMetadata> => {
  const command = new Deno.Command("cargo", {
    args: ["metadata", "--format-version=1"],
    stdout: "piped",
    stderr: "piped",
    cwd: fromFileUrl(rootUrl),
  })
  const output = await command.output()
  if (!output.success) {
    const stderr = decoder.decode(output.stderr).trim()
    throw new Error(`cargo metadata failed${stderr ? `: ${stderr}` : ""}`)
  }
  return JSON.parse(decoder.decode(output.stdout)) as CargoMetadata
})()

const includeAllFiles = async (...relativePaths: string[]) => {
  const metadata = await cargoMetadataPromise
  const workspaceMembers = new Set(metadata.workspace_members)
  const fullPaths = new Set(
    metadata.packages
      .filter((cargoPackage) => workspaceMembers.has(cargoPackage.id))
      .flatMap((cargoPackage) => relativePaths.map((path) => join(dirname(cargoPackage.manifest_path), path))),
  )
  if (relativePaths.includes("Cargo.toml")) fullPaths.add(join(metadata.workspace_root, "Cargo.toml"))
  const candidates = [...fullPaths]
    .map((path) => ({
      fullPath: path,
      renderedPath: relative(rootPath, path).replaceAll("\\", "/"),
    }))
    .sort((left, right) => left.renderedPath.localeCompare(right.renderedPath))
  const files = (await Promise.all(
    candidates.map(async ({ fullPath, renderedPath }) => {
      if (!(await fileExists(fullPath))) return null
      return await renderFileContents(fullPath, await Deno.readTextFile(fullPath), renderedPath)
    }),
  )).filter((file): file is string => file !== null)
  return files.join("\n\n")
}

const parseSemVer = (value: string) => {
  const parsed = parse(value)
  if (!parsed) throw new Error(`invalid semver: '${value}'`)
  return parsed
}

const hasDirectDependency = (metadata: CargoMetadata, dependencyName: string) => {
  const resolve = metadata.resolve
  if (!resolve) return false
  const workspaceMembers = new Set(metadata.workspace_members)
  const matchingPackages = new Set(
    metadata.packages.filter((pkg) => pkg.name === dependencyName).map((pkg) => pkg.id),
  )
  return resolve.nodes.some(
    (node) =>
      workspaceMembers.has(node.id) &&
      node.deps.some(
        (dependency) => dependency.name === dependencyName || matchingPackages.has(dependency.pkg),
      ),
  )
}

const includeFileIfCargoDependencyExists = async (dependencyName: string, path: string) => {
  const metadata = await cargoMetadataPromise
  if (!hasDirectDependency(metadata, dependencyName)) return null
  return await includeFile(path)
}

const includeCargoDependencyFileIfExists = async (dependencyName: string, path: string) => {
  const metadata = await cargoMetadataPromise
  const candidates = metadata.packages.filter((pkg) => pkg.name === dependencyName)
  if (candidates.length === 0) return null
  const cargoPackage = candidates.reduce((best, current) => {
    if (!best) return current
    const comparison = compare(parseSemVer(current.version), parseSemVer(best.version))
    if (comparison > 0) {
      return current
    }
    if (comparison === 0 && current.manifest_path > best.manifest_path) {
      return current
    }
    return best
  }, null as CargoPackage | null)
  if (!cargoPackage) {
    throw new Error(`cargo package not found for dependency: '${dependencyName}'`)
  }
  const crateRoot = dirname(cargoPackage.manifest_path)
  const fullPath = join(crateRoot, path)
  if (!(await fileExists(fullPath))) return null
  return await renderFileContents(path, await Deno.readTextFile(fullPath), `${dependencyName}/${path}`)
}

const includeFileIfExists = async (path: string) => {
  if (!(await fileExists(path))) return null
  return await includeFile(path)
}

const renderSection = async (heading: string, ...bodyPartPromises: Promise<string | null>[]) => {
  const body = (await Promise.all(bodyPartPromises))
    .filter((part): part is string => part !== null && part.length > 0)
    .join("\n\n")
  return body.length > 0 ? `${heading}\n\n${body}` : null
}

const parts = (await Promise.all([
  `<!-- This file is autogenerated by ${basename(sourcePath)} -->`,
  renderSection(
    "# Guidelines",
    includeFile(".agents/general.md"),
    includeFileIfCargoDependencyExists("serde", ".agents/crates/serde.md"),
    includeFileIfCargoDependencyExists("subtype", ".agents/crates/subtype.md"),
    includeFileIfCargoDependencyExists("clap", ".agents/crates/clap.md"),
    includeFileIfCargoDependencyExists("clap", ".agents/cli.md"),
    includeFileIfExists(".agents/project.md"),
    includeFileIfExists(".agents/knowledge.md"),
    includeFileIfExists(".agents/docs.md"),
    includeFileIfExists(".agents/api.md"),
    includeFileIfExists(".agents/gotchas.md"),
    includeCargoDependencyFileIfExists("errgonomic", "DOCS.md"),
  ),
  renderSection(
    "## Project files",
    includeAllFiles("Cargo.toml"),
    includeFile("fnox.toml"),
    includeAllFiles("src/lib.rs", "src/main.rs"),
  ),
])).filter((part): part is string => !!part && part.length > 0)

const content = parts.join("\n\n")

/// PRUNING: Removes only an uncommitted temporary AGENTS render after replacement or failure because it contains no user-owned data.
const removeTemporaryAgents = async (path: string) => {
  try {
    await Deno.remove(path)
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error
  }
}

const destinationPath = join(rootPath, `${basename(sourcePath, extname(sourcePath))}.md`)
const temporaryPath = await Deno.makeTempFile({
  dir: dirname(destinationPath),
  prefix: ".AGENTS.",
  suffix: ".tmp",
})
try {
  // The file must be writable by the `agent` user in the sandbox (not read-only)
  await Deno.writeTextFile(temporaryPath, `${content}\n`)
  await Deno.chmod(temporaryPath, 0o644)
  await Deno.rename(temporaryPath, destinationPath)
} finally {
  await removeTemporaryAgents(temporaryPath)
}
