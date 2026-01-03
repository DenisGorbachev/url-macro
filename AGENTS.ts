#!/usr/bin/env -S deno run --allow-read --allow-write --no-lock

import {parseArgs} from "jsr:@std/cli@1.0.13"
import {stringify} from "jsr:@libs/xml@7.0.3"
import remarkHeadingShift from "npm:remark-heading-shift@1.1.2"
import remarkParse from "npm:remark-parse@11.0.0"
import remarkStringify from "npm:remark-stringify@11.0.0"
import {unified} from "npm:unified@11.0.5"

const args = parseArgs(Deno.args, {
  string: ["output"],
  alias: {
    output: "o",
  },
})

const rootUrl = new URL(".", import.meta.url)

const requiredFiles = [
  ".agents/general.md",
  ".agents/error-handling.md",
  "Cargo.toml",
]

const optionalFiles = [
  ".agents/project.md",
  ".agents/knowledge.md",
  ".agents/gotchas.md",
  "src/main.rs",
  "src/lib.rs",
]

const isMarkdownPath = (path: string) => path.toLowerCase().endsWith(".md")

const resolvePath = (path: string) => new URL(path, rootUrl)

const fileExists = async (path: string) => {
  try {
    await Deno.stat(resolvePath(path))
    return true
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      return false
    }
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

const renderXmlFile = (path: string, contents: string) =>
  stringify(
    {
      file: {
        path,
        contents,
      },
    },
    {
      format: {
        indent: "  ",
        breakline: 0,
      },
    },
  ).trimEnd()

const includeFile = async (path: string) => {
  const contents = await Deno.readTextFile(resolvePath(path))
  if (isMarkdownPath(path)) {
    return await shiftHeadings(contents)
  }
  return renderXmlFile(path, contents)
}

const includeFileIfExists = async (path: string) => {
  const exists = await fileExists(path)
  if (!exists) {
    return null
  }
  return await includeFile(path)
}

const parts: string[] = ["# Guidelines"]

for (const path of requiredFiles) {
  const rendered = await includeFileIfExists(path)
  if (!rendered) {
    throw new Error(`Required file is missing: ${path}`)
  }
  if (rendered.length > 0) {
    parts.push(rendered)
  }
}

for (const path of optionalFiles) {
  const rendered = await includeFileIfExists(path)
  if (rendered && rendered.length > 0) {
    parts.push(rendered)
  }
}

const content = parts.join("\n\n")

if (args.output) {
  await Deno.writeTextFile(args.output, `${content}\n`)
  await Deno.chmod(args.output, 0o444)
} else {
  console.info(content)
}
