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

type FileSpec = {
  path: string
  required: boolean
}

const fileSpecs: FileSpec[] = [
  {path: ".agents/general.md", required: true},
  {path: ".agents/project.md", required: false},
  {path: ".agents/knowledge.md", required: false},
  {path: ".agents/gotchas.md", required: false},
  {path: ".agents/error-handling.md", required: true},
  {path: "Cargo.toml", required: true},
  {path: "src/main.rs", required: false},
  {path: "src/lib.rs", required: false},
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

const parts: string[] = ["# Guidelines"]

for (const spec of fileSpecs) {
  const exists = await fileExists(spec.path)
  if (!exists) {
    if (spec.required) {
      throw new Error(`Required file is missing: ${spec.path}`)
    }
    continue
  }
  const rendered = await includeFile(spec.path)
  if (rendered.length > 0) {
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
