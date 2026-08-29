#!/usr/bin/env -S deno run --node-modules-dir=false --allow-read --allow-write --allow-run --allow-env=HOME --no-lock

import {CargoMetadataSchema, PackageMetadataSchema, selectWorkspacePackages} from "./CargoMetadata.ts"
import type {CargoMetadata, CargoPackage} from "./CargoMetadata.ts"
import {compare, parse} from "jsr:@std/semver@1.0.0"
import {stringify} from "jsr:@libs/xml@7.0.3"
import remarkParse from "npm:remark-parse@11.0.0"
import {unified} from "npm:unified@11.0.5"
import {visit} from "npm:unist-util-visit@5.0.0"
import {basename, dirname, extname, fromFileUrl, isAbsolute, join, relative, resolve, SEPARATOR} from "jsr:@std/path@1.1.4"

const sourcePath = fromFileUrl(import.meta.url)
const rootPath = dirname(sourcePath)
const decoder = new TextDecoder()
const homePath = Deno.env.get("HOME")
if (!homePath) throw new Error("HOME is not set")
if (!isAbsolute(homePath)) throw new Error("HOME is not an absolute path")

const isMarkdownPath = (path: string) => path.toLowerCase().endsWith(".md")
const resolvePath = (path: string) => resolve(rootPath, path)
const posixPath = (path: string) => SEPARATOR === "/" ? path : path.replaceAll(SEPARATOR, "/")

const renderPath = (path: string) => {
  if (!isAbsolute(path)) return posixPath(path)
  const resolvedPath = resolvePath(path)
  const relativeToHome = relative(homePath, resolvedPath)
  if (!relativeToHome) return "~"
  if (isAbsolute(relativeToHome) || relativeToHome === ".." || relativeToHome.startsWith(`..${SEPARATOR}`)) return posixPath(resolvedPath)
  return `~/${posixPath(relativeToHome)}`
}

const renderCommand = (command: string, args: string[]) => [command, ...args].join(" ")

const renderCommandOutput = (stdout: Uint8Array, stderr: Uint8Array) => `stdout:
${decoder.decode(stdout)}
stderr:
${decoder.decode(stderr)}`

const runCommand = async (command: string, args: string[]) => {
  const output = await new Deno.Command(command, {args, cwd: rootPath, stdout: "piped", stderr: "piped"}).output()
  if (!output.success) {
    throw new Error(`'${renderCommand(command, args)}' failed:\n${renderCommandOutput(output.stdout, output.stderr)}`)
  }
  return decoder.decode(output.stdout).trimEnd()
}

const fileExists = async (path: string) => {
  try {
    await Deno.stat(resolvePath(path))
    return true
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) return false
    throw error
  }
}

/// PRUNING: Replaces Markdown heading syntax so included headings are nested under their generated section heading.
const shiftHeadings = (markdown: string, headingLevel: number) => {
  const edits: { start: number; end: number; replacement: string }[] = []
  visit(unified().use(remarkParse).parse(markdown), "heading", (heading) => {
    const start = heading.position?.start
    const end = heading.position?.end
    if (start?.offset === undefined || end?.offset === undefined) throw new Error("heading position is missing")
    const depth = Math.min(6, Math.max(1, heading.depth + headingLevel - 1))
    const markerEnd = start.offset + heading.depth
    if (markdown.slice(start.offset, markerEnd) === "#".repeat(heading.depth)) {
      edits.push({start: start.offset, end: markerEnd, replacement: "#".repeat(depth)})
      return
    }
    const lines = markdown.slice(start.offset, end.offset).split(/\r?\n/)
    lines.pop()
    const indentation = Math.max(0, start.column - 1)
    const contents = lines.map((line, index) => index === 0 ? line : line.slice(indentation)).join(" ")
    edits.push({start: start.offset, end: end.offset, replacement: `${"#".repeat(depth)} ${contents}`})
  })
  return edits.reduceRight(
    (source, edit) => source.slice(0, edit.start) + edit.replacement + source.slice(edit.end),
    markdown,
  ).trimEnd()
}

const renderCodeSection = (heading: string, contents: string, languageIdentifier: string, headingLevel: number) => {
  contents = contents.trimEnd()
  const fence = getFence(contents)
  return `${"#".repeat(headingLevel)} ${heading}\n\n${fence}${languageIdentifier}\n${contents}\n${fence}`
}

const renderCodeFile = (path: string, contents: string, headingLevel: number) =>
  renderCodeSection(path, contents, getLanguageIdentifier(path), headingLevel)

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
    {file: {path, contents: "\n" + contents}},
    {format: {indent: "", breakline: 0}},
  ).trimEnd()

const includeFile = async (path: string, headingLevel = 3) => renderFileContents(path, await Deno.readTextFile(resolvePath(path)), renderPath(path), headingLevel)

const includeCommand = async (command: string, args: string[], headingLevel = 3) => {
  const stdout = await runCommand(command, args)
  return renderCodeSection(`\`${renderCommand(command, args)}\``, stdout, "shell", headingLevel)
}

const renderFileContents = (path: string, contents: string, pathToRender: string, headingLevel: number) => isMarkdownPath(path) ? shiftHeadings(contents, headingLevel) : renderCodeFile(pathToRender, contents, headingLevel)

export const runAgentDocsList = async (): Promise<string[]> => {
  const stdout = await runCommand("mise", ["run", "agent:docs:list"])
  return stdout ? stdout.split(/\r?\n/).filter((line) => line.length > 0) : []
}

export const includeAgentDocs = async () => {
  const files = await runAgentDocsList()
  if (!files.length) return ""
  return `### Extra docs

Read the extra docs from the list below if they are relevant to your current task:

${files.map((file) => `* ${file}`).join("\n")}`.trim()
}

const readCargoMetadata = async (): Promise<CargoMetadata> => {
  const stdout = await runCommand("cargo", ["metadata", "--format-version=1"])
  try {
    return CargoMetadataSchema.parse(JSON.parse(stdout))
  } catch (cause) {
    throw new Error("cargo metadata output is invalid", {cause})
  }
}

let cargoMetadataPromise: Promise<CargoMetadata> | undefined
const getCargoMetadata = () => cargoMetadataPromise ??= readCargoMetadata()

const includeAllCargoFiles = async (relativePaths: string[], headingLevel: number) => {
  const metadata = await getCargoMetadata()
  const fullPaths = new Set(
    selectWorkspacePackages(metadata)
      .flatMap((cargoPackage) => relativePaths.map((path) => join(dirname(cargoPackage.manifest_path), path))),
  )
  if (relativePaths.includes("Cargo.toml")) fullPaths.add(join(metadata.workspace_root, "Cargo.toml"))
  const candidates = [...fullPaths]
    .map((path) => ({
      fullPath: path,
      renderedPath: posixPath(relative(rootPath, path)),
    }))
    .sort((left, right) => left.renderedPath.localeCompare(right.renderedPath))
  return (await Promise.all(
    candidates.map(async ({fullPath, renderedPath}) => {
      if (!(await fileExists(fullPath))) return null
      return renderFileContents(fullPath, await Deno.readTextFile(fullPath), renderedPath, headingLevel)
    }),
  )).filter((file): file is string => file !== null).join("\n\n")
}

const parseSemVer = (value: string) => {
  const parsed = parse(value)
  if (!parsed) throw new Error(`invalid semver: '${value}'`)
  return parsed
}

const hasDirectDependency = (metadata: CargoMetadata, dependencyName: string) => {
  const workspaceMembers = new Set(metadata.workspace_members)
  const matchingPackages = new Set(
    metadata.packages.filter((pkg) => pkg.name === dependencyName).map((pkg) => pkg.id),
  )
  return metadata.resolve?.nodes.some(
    (node) =>
      workspaceMembers.has(node.id) &&
      node.deps.some(
        (dependency) => dependency.name === dependencyName || matchingPackages.has(dependency.pkg),
      ),
  ) ?? false
}

const getPackageProfiles = (cargoPackage: CargoPackage) => {
  try {
    return PackageMetadataSchema.parse(cargoPackage.metadata).details.profiles
  } catch (cause) {
    throw new Error(`package metadata in '${renderPath(cargoPackage.manifest_path)}' is invalid`, {cause})
  }
}

const hasPackageProfile = (metadata: CargoMetadata, profile: string) => {
  return selectWorkspacePackages(metadata).some((cargoPackage) => getPackageProfiles(cargoPackage).includes(profile))
}

const includeFileIfPackageProfileIsEnabled = async (profile: string, path: string, headingLevel = 3) => {
  const metadata = await getCargoMetadata()
  return hasPackageProfile(metadata, profile) ? await includeFile(path, headingLevel) : null
}

const includeFileIfCargoDependencyExists = async (dependencyName: string, path: string, headingLevel = 3) => {
  const metadata = await getCargoMetadata()
  return hasDirectDependency(metadata, dependencyName) ? await includeFile(path, headingLevel) : null
}

const includeCargoDependencyFileIfExists = async (dependencyName: string, path: string, headingLevel = 3) => {
  const metadata = await getCargoMetadata()
  const candidates = metadata.packages.filter((pkg) => pkg.name === dependencyName)
  if (candidates.length === 0) return null
  const cargoPackage = candidates.reduce((best, current) => {
    const comparison = compare(parseSemVer(current.version), parseSemVer(best.version))
    return comparison > 0 || comparison === 0 && current.manifest_path > best.manifest_path ? current : best
  })
  const crateRoot = dirname(cargoPackage.manifest_path)
  const fullPath = join(crateRoot, path)
  if (!(await fileExists(fullPath))) return null
  return renderFileContents(path, await Deno.readTextFile(fullPath), `${dependencyName}/${path}`, headingLevel)
}

const includeFileIfExists = async (path: string, headingLevel = 3) => {
  return await fileExists(path) ? await includeFile(path, headingLevel) : null
}

const renderSection = async (heading: string, bodyPartPromises: Promise<string | null>[]) => {
  const body = (await Promise.all(bodyPartPromises))
    .filter((part): part is string => part !== null && part.length > 0)
    .join("\n\n")
  return body.length > 0 ? `${heading}\n\n${body}` : null
}

const parts = (await Promise.all([
  `<!-- This file is autogenerated by ${basename(sourcePath)} -->`,
  renderSection(
    "## Guidelines",
    [
      includeFile(".agents/general.md"),
      includeFileIfCargoDependencyExists("serde", ".agents/crates/serde.md"),
      includeFileIfCargoDependencyExists("subtype", ".agents/crates/subtype.md"),
      includeFileIfCargoDependencyExists("clap", ".agents/crates/clap.md"),
      includeFileIfCargoDependencyExists("clap", ".agents/cli.md"),
      includeFileIfExists(".agents/project.md"),
      includeFileIfExists(".agents/knowledge.md"),
      includeFileIfExists(".agents/docs.md"),
      includeFileIfPackageProfileIsEnabled("api-client", ".agents/api.md"),
      includeFileIfExists(".agents/gotchas.md"),
      includeCargoDependencyFileIfExists("errgonomic", "DOCS.md"),
    ],
  ),
  renderSection(
    "### Project info",
    [
      includeCommand("git", ["remote"], 4),
    ],
  ),
  renderSection(
    "### Project files",
    [
      includeFile("mise.toml", 4),
      includeFile("fnox.toml", 4),
      includeAllCargoFiles(["Cargo.toml"], 4),
      includeAllCargoFiles(["src/lib.rs", "src/main.rs"], 4),
    ],
  ),
])).filter((part): part is string => !!part)

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
  dir: rootPath,
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
