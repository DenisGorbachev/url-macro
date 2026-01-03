#!/usr/bin/env -S deno run --allow-write --allow-read --allow-env --allow-sys --allow-run=bash,git --no-lock

// NOTE: Pin the versions of the packages because the script runs without a lock file
import * as zx from "npm:zx@8.3.2"
import {ProcessPromise, Shell} from "npm:zx@8.3.2"
import {z, ZodSchema, ZodTypeDef} from "https://deno.land/x/zod@v3.23.8/mod.ts"
import {parseArgs} from "jsr:@std/cli@1.0.13"

const args = parseArgs(Deno.args, {
  string: ["output"],
  alias: {
    output: "o",
  },
})

const SectionSchema = z.object({
  title: z.string().min(1),
  body: z.string(),
})

type Section = z.infer<typeof SectionSchema>

const section = (title: string, body: string): Section => SectionSchema.parse({title, body})

const pushSection = (sections: Section[], title: string, body: string) => sections.push(section(title, body))

// Nested sections not supported
const renderSection = ({title, body}: Section) => `## ${title}\n\n${body}`

const renderNonEmptySections = (sections: Section[]) => sections.filter((s) => s.body).map(renderSection).join("\n\n")

const stub = <T>(message = "Implement me"): T => {
  throw new Error(message)
}

const dirname = import.meta.dirname
if (!dirname) throw new Error("Cannot determine the current script dirname")

const $: Shell<false, ProcessPromise> = zx.$({cwd: dirname})

const parseProcessOutput = (input: zx.ProcessOutput) => JSON.parse(input.stdout)
// deno-lint-ignore no-explicit-any
const parse = <Output = any, Def extends ZodTypeDef = ZodTypeDef, Input = Output>(schema: ZodSchema<Output, Def, Input>, input: zx.ProcessOutput) => schema.parse(parseProcessOutput(input))
const nail = (str: string) => {
  const spacesAtStart = str.match(/^\n(\s+)/)
  if (spacesAtStart?.[1]) {
    return str.replace(new RegExp(`^[^\\S\r\n]{0,${spacesAtStart[1].length}}`, "gm"), "")
  } else {
    return str
  }
}

const body = ""
const title = `# Guidelines`

const contentArray = [title, body]
const content = contentArray.filter(s => s.length > 0).join("\n\n");

if (args.output) {
  await Deno.writeTextFile(args.output, content + "\n")
} else {
  console.info(content)
}
