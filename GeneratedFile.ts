export const fix = Deno.args.length === 1 && Deno.args.includes("--fix")
if (Deno.args.length > 0 && !fix) throw new Error("Expected no arguments to check generated files, or --fix to update them")

export const checkGeneratedFile = async (path: string, expected: string) => {
  let actual: string | undefined
  try {
    actual = await Deno.readTextFile(path)
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) throw error
  }
  if (actual !== expected) throw new Error(`Generated file '${path}' is missing or stale; rerun its generator with --fix`)
}
