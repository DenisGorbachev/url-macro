import { z } from "https://deno.land/x/zod@v3.23.8/mod.ts"

export { z }

export const ReadmeSchema = z.object({
  generate: z.boolean().optional(),
}).default({})

export const PackageDetailsSchema = z.object({
  title: z.string().nullable().optional(),
  readme: ReadmeSchema,
  peers: z.array(z.string()).default([]).describe("Packages that should be installed alongside this package"),
  profiles: z.array(z.string().min(1)).default([]),
}).default({})

const PackageMetadataObjectSchema = z.object({
  details: PackageDetailsSchema,
})

export const PackageMetadataSchema = PackageMetadataObjectSchema.nullable()
  .transform((value) => PackageMetadataObjectSchema.parse(value ?? {}))
  .default({})

/// Validates fields shared by metadata consumers while keeping arbitrary package metadata opaque.
export const CargoPackageSchema = z.object({
  id: z.string().min(1),
  manifest_path: z.string().min(1),
  name: z.string().min(1),
  version: z.string().min(1),
  metadata: z.record(z.unknown()).nullable(),
})

const CargoDependencySchema = z.object({
  name: z.string().min(1),
  pkg: z.string().min(1),
})

const CargoResolveNodeSchema = z.object({
  id: z.string().min(1),
  deps: z.array(CargoDependencySchema),
})

const CargoResolveSchema = z.object({
  nodes: z.array(CargoResolveNodeSchema),
}).nullable()

export const CargoMetadataSchema = z.object({
  packages: z.array(CargoPackageSchema),
  resolve: CargoResolveSchema,
  workspace_members: z.array(z.string().min(1)),
  workspace_root: z.string().min(1),
})

export type CargoPackage = z.infer<typeof CargoPackageSchema>
export type CargoMetadata = z.infer<typeof CargoMetadataSchema>

type CargoMetadataWithPackages<PackageType extends { id: string }> = {
  packages: PackageType[]
  workspace_members: string[]
}

export const selectWorkspacePackages = <PackageType extends { id: string }>(metadata: CargoMetadataWithPackages<PackageType>) => {
  const workspaceMemberIds = new Set(metadata.workspace_members)
  return metadata.packages.filter((cargoPackage) => workspaceMemberIds.has(cargoPackage.id))
}
