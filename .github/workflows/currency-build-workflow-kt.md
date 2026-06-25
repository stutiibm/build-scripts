# Currency Build Workflow - Knowledge Transfer Document

## Overview

The **Currency Build Workflow** is a GitHub Actions pipeline designed to build, test, and scan Python packages for the ppc64le architecture. It supports multiple Python versions, wheel building, Docker image creation, and comprehensive security scanning.

---

## Workflow Trigger

**File**: `.github/workflows/currency-build.yaml`

**Trigger Type**: `workflow_dispatch` (Manual trigger only)

**Branches**: 
- `master`


---

## Input Parameters

| Parameter | Description | Required | Default | Type |
|-----------|-------------|----------|---------|------|
| `package_name` | Name of the package to build | Yes | - | string |
| `version` | Version of the package | Yes | - | string |
| `validate_build_script` | Run build validation script | Yes | `false` | boolean |
| `wheel_build` | Create wheel for different Python versions | Yes | `false` | boolean |
| `build_docker` | Build docker image | Yes | `false` | boolean |
| `enable_trivy` | Enable Trivy scan | Yes | `true` | boolean |
| `enable_syft` | Enable Syft scan | Yes | `true` | boolean |
| `enable_grype` | Enable Grype scan | Yes | `true` | boolean |
| `unique_id` | Unique ID for the build | No | `None` | string |
| `large-runner-label` | Runner for failing builds | No | - | choice |

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CURRENCY BUILD WORKFLOW                   │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   build_info     │  ← Reads build_info.json, creates package-cache
└────────┬─────────┘
         │
         ├─────────────────────────────────────────────────────────┐
         │                                                           │
         ▼                                                           ▼
┌────────────────┐                                    ┌──────────────────────┐
│     build      │ (if validate_build_script=true)    │   build_docker       │
│                │                                     │                      │
│ - Builds pkg   │                                     │ - Builds Docker img  │
│ - Uploads logs │                                     │ - Saves image.tar    │
└────────┬───────┘                                     └──────────┬───────────┘
         │                                                        │
         ▼                                                        ▼
┌────────────────┐                                    ┌──────────────────────┐
│ source_scanner │                                    │   image_scanner      │
│                │                                    │                      │
│ - Trivy scan   │                                    │ - Trivy scan         │
│ - Syft scan    │                                    │ - Syft scan          │
│ - Grype scan   │                                    │ - Grype scan         │
└────────────────┘                                    └──────────────────────┘

         │
         ├──────────────────────────────────────────────────────────┐
         │                                                            │
         ▼                                                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    WHEEL BUILD JOBS (Parallel)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐│
│  │ wheel_py310  │  │ wheel_py311  │  │ wheel_py312  │  │ wheel_py313 ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘│
│  ┌──────────────┐                                                       │
│  │ wheel_py314  │  (if wheel_build=true)                               │
│  └──────────────┘                                                       │
└─────────────────────────────────────────────────────────────────────────┘
         │
         ├──────────────────────────────────────┐
         │                                       │
         ▼                                       ▼
┌────────────────┐                    ┌──────────────────┐
│ wheel_licenses │                    │  wheel_scanner   │
│                │                    │                  │
│ - Scancode     │                    │ - Grype scan     │
│ - License scan │                    │ - Vulnerability  │
└────────────────┘                    └──────────────────┘
         │
         │
         ▼
┌────────────────┐
│ final_summary  │
│                │
│ - Aggregates   │
│ - Processes    │
│ - Reports      │
└────────────────┘
```

---

## Job Flow Details

### 1. **build_info** Job

**Purpose**: Initialize the build environment and extract package metadata

**Runner**: `ubuntu-24.04-ppc64le-p10`

**Key Steps**:
1. Checkout code
2. Install system packages (`jq`, `file`)
3. Install Python dependencies
4. Execute `read_buildinfo.sh` to parse `build_info.json`
5. Create `scanner-env.sh` with environment variables
6. Archive and upload `package-cache` artifact

**Outputs**:
- `package-cache.tar.gz` containing:
  - `variable.sh` (build variables)
  - `scanner-env.sh` (scanner configuration)

---

### 2. **build** Job

**Purpose**: Build the package from source

**Condition**: `validate_build_script == 'true'`

**Runner**: Dynamic (uses `large-runner-label` if provided, else default)

**Key Steps**:
1. Download `package-cache` artifact
2. Source environment variables
3. Execute `build_package.sh`
4. Run `pre_process.sh` for post-build processing
5. Compress and upload `build_log.gz`
6. Upload updated `package-cache` with cloned package

**Artifacts**:
- `updated-package-cache` (includes built package)
- `build_log.gz` (uploaded to external storage)

---

### 3. **wheel_build_py3XX** Jobs (5 parallel jobs)

**Purpose**: Build Python wheels for different Python versions

**Versions**: 3.10, 3.11, 3.12, 3.13, 3.14

**Condition**: `wheel_build == 'true'`

**Runner**: Dynamic

**Key Steps**:
1. Download `package-cache`
2. Set `PYTHON_VERSION` environment variable
3. Execute `build_wheels.sh`
4. Compress and upload wheel build logs
5. Upload wheel file with SHA256 checksum

**Special Notes**:
- Python 3.13 and 3.14 have `continue-on-error: true` (experimental)
- Each job uploads its wheel independently

---

### 4. **wheel_licenses** Job

**Purpose**: Scan wheels for license compliance

**Condition**: `always() && wheel_build == 'true'`

**Dependencies**: All wheel_build jobs

**Key Steps**:
1. Download all built wheels using `download_wheels.sh`
2. Run `scancode_wheel_scan.sh` for license scanning
3. Collect `*_output.json` files
4. Upload `wheel_scanner.tar.gz`

---

### 5. **wheel_scanner** Job

**Purpose**: Scan wheels for vulnerabilities

**Condition**: `always() && wheel_build == 'true'`

**Dependencies**: All wheel_build jobs

**Key Steps**:
1. Download all built wheels
2. Run `grype_wheel_scan.sh` for vulnerability scanning
3. Collect scan results
4. Upload `grype_wheel_scanner.tar.gz`

---

### 6. **source_scanner** Job

**Purpose**: Scan source code for vulnerabilities and generate SBOM

**Condition**: `validate_build_script == 'true'`

**Dependencies**: `build` job

**Scanners**:
- **Trivy** (if `enable_trivy == 'true'`):
  - Vulnerability scan
  - SBOM generation (CycloneDX format)
  
- **Syft** (if `enable_syft == 'true'`):
  - SBOM generation
  
- **Grype** (if `enable_grype == 'true'`):
  - Vulnerability scan
  - SBOM generation

**Output**: `source_scanner.tar.gz`

---

### 7. **build_docker** Job

**Purpose**: Build Docker image for the package

**Condition**: `build_docker == 'true'`

**Key Steps**:
1. Execute `build_docker.sh`
2. Save Docker image as `image.tar`
3. Upload Docker image to external storage
4. Upload `package-cache-with-image` artifact

---

### 8. **image_scanner** Job

**Purpose**: Scan Docker image for vulnerabilities

**Condition**: `build_docker == 'true'`

**Dependencies**: `build_docker` job

**Key Steps**:
1. Load Docker image from `image.tar`
2. Run Trivy, Syft, and Grype scans on the image
3. Upload `image_scanner.tar.gz`

---

### 9. **final_summary** Job

**Purpose**: Aggregate all results and generate final report

**Condition**: `always() && build.result == 'success' && source_scanner.result == 'success'`

**Dependencies**: All major jobs

**Key Steps**:
1. Create Python virtual environment
2. Install dependencies (`requests`, `xlsxwriter`, `packaging`)
3. Execute `run_currency_processor` to generate final report
4. Upload consolidated results

---

## Key Scripts

| Script | Purpose |
|--------|---------|
| `read_buildinfo.sh` | Parse `build_info.json` and extract variables |
| `build_package.sh` | Build package from source |
| `build_wheels.sh` | Build Python wheels |
| `build_docker.sh` | Build Docker image |
| `pre_process.sh` | Post-build processing |
| `download_wheels.sh` | Download built wheels from storage |
| `upload_file.sh` | Upload files to external storage |
| `upload_wheel.sh` | Upload wheel with checksum |
| `upload_docker_image.sh` | Upload Docker image |
| `trivy_code_scan.sh` | Trivy source code scan |
| `syft_code_scan.sh` | Syft source code scan |
| `grype_code_scan.sh` | Grype source code scan |
| `scancode_wheel_scan.sh` | Scancode license scan for wheels |
| `grype_wheel_scan.sh` | Grype vulnerability scan for wheels |
| `trivy_image_scan.sh` | Trivy Docker image scan |
| `syft_image_scan.sh` | Syft Docker image scan |
| `grype_image_scan.sh` | Grype Docker image scan |

---

## Artifact Flow

```
┌─────────────┐
│ build_info  │
└──────┬──────┘
       │
       │ Creates: package-cache.tar.gz
       │ Contains: variable.sh, scanner-env.sh
       │
       ▼
┌─────────────┐
│    build    │
└──────┬──────┘
       │
       │ Updates: package-cache → updated-package-cache
       │ Adds: cloned package directory
       │
       ├──────────────────────────────────┐
       │                                   │
       ▼                                   ▼
┌──────────────┐                  ┌──────────────┐
│ wheel_builds │                  │ build_docker │
└──────┬───────┘                  └──────┬───────┘
       │                                  │
       │ Uploads: individual wheels       │ Adds: image.tar
       │                                  │
       ▼                                  ▼
┌──────────────┐                  ┌──────────────┐
│   scanners   │                  │image_scanner │
└──────────────┘                  └──────────────┘
```

---

## Security Scanning Tools

### Trivy
- **Type**: Vulnerability scanner
- **Outputs**: 
  - Vulnerability results (JSON)
  - SBOM (CycloneDX format)
- **Targets**: Source code, Docker images

### Syft
- **Type**: SBOM generator
- **Outputs**: SBOM (JSON)
- **Targets**: Source code, Docker images

### Grype
- **Type**: Vulnerability scanner
- **Outputs**: 
  - Vulnerability results (JSON)
  - SBOM (JSON)
- **Targets**: Source code, Docker images, wheels

### Scancode
- **Type**: License scanner
- **Outputs**: License information (JSON)
- **Targets**: Python wheels

---

## Runner Configuration

**Default Runner**: `ubuntu-24.04-ppc64le-p10`

**Large Runners** (for retries):
- `ubuntu-24.04-ppc64le-2xlarge-p10`
- `ubuntu-24.04-ppc64le-4xlarge-p10`

**Architecture**: ppc64le (IBM POWER)

---

## Environment Variables

### Secrets
- `GHA_CURRENCY_SERVICE_ID_API_KEY`: API key for currency service
- `GHA_CURRENCY_SERVICE_ID`: Service ID for currency service
- `IAM_WRITER_API_KEY`: IAM API key for writing results
- `SERVICE_INSTANCE_ID`: Service instance identifier

### Dynamic Variables (from build_info.json)
- `PACKAGE_NAME`: Name of the package
- `VERSION`: Package version
- `PACKAGE_DIR`: Package directory path
- `IMAGE_NAME`: Docker image name
- `CLONED_PACKAGE`: Cloned package directory name

---

## Error Handling

1. **Wheel builds (py313, py314)**: `continue-on-error: true` (experimental versions)
2. **Scanner jobs**: Use `always()` condition to run even if dependencies fail
3. **Final summary**: Only runs if core jobs succeed
4. **Large runner fallback**: Can retrigger failed builds on larger runners

---

## Best Practices

1. **Always specify unique_id**: Helps track builds across retries
2. **Enable all scanners**: Comprehensive security coverage
3. **Review scanner results**: Check uploaded scan reports
4. **Monitor build logs**: Logs are uploaded for debugging
5. **Use large runners for heavy packages**: Prevents timeout/OOM issues

---

## Troubleshooting

### Build Fails
- Check `build_log.gz` in external storage
- Verify `build_info.json` is correctly formatted
- Ensure build script has proper permissions

### Wheel Build Fails
- Check Python version compatibility
- Review wheel build logs (uploaded per version)
- Verify dependencies are available for ppc64le

### Scanner Fails
- Ensure scanner tools are installed on runner
- Check network connectivity for vulnerability databases
- Review scanner-specific logs

### Docker Build Fails
- Verify Dockerfile exists and is valid
- Check base image availability for ppc64le
- Review Docker build logs

---

## Maintenance Notes

- **Python versions**: Update as new versions are released
- **Scanner versions**: Keep tools updated for latest CVE databases
- **Runner images**: Coordinate with infrastructure team for updates
- **Scripts**: Located in `gha-script/` directory

---

## Related Workflows

- **PR Build Workflow** (`.github/workflows/pr-build.yaml`): Validates changes in pull requests
- Shares similar structure but with conditional execution based on changed files

---

## Contact & Support

For issues or questions:
1. Check workflow run logs in GitHub Actions
2. Review uploaded artifacts and scan results
3. Contact the build team for assistance

---

**Document Version**: 1.0  
**Last Updated**: 2026-06-20  
**Maintained By**: Build Engineering Team