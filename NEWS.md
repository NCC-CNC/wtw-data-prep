# wtw-data-prep 1.1.2

### Minor changes and bug fixes

- New `downloadable` field for `Features`, `Weights`, `Includes`, `Excludes` 
and `Solutions`. When `downloadable` is set to `FALSE`, the spatial layer will not 
be available for export.

# wtw-data-prep 1.0.0

### Major changes
- requires R version 4.4.1 and wheretowork version 1.0.0.
- requires NAT_1KM_20240729 data version or greater.
- requires RTools44.
- migrated from raster package to terra package.

### Minor changes and bug fixes
- The write_project function now automatically includes the wheretowork and 
prioritizr package version number to the attribute.yaml.


# wtw-data-prep 0.0.0.9000

- requires R version 4.1.2 and wheretowork version 0.0.9000.
- requires NAT_1KM_20240626 data version or less.
- requires RTools40.
- requires both raster and terra to run.
