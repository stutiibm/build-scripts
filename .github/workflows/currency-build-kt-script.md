# Currency Build Workflow - KT Session Script

## Session Overview
**Duration**: 45-60 minutes  
**Audience**: Development team, DevOps engineers  
**Prerequisites**: Basic understanding of GitHub Actions, CI/CD concepts

---

## Introduction (5 minutes)

### Opening
"Good morning/afternoon everyone. Today I'll be walking you through our Currency Build Workflow, which is the backbone of our package building and security scanning process for ppc64le architecture."

### Agenda
1. Workflow overview and purpose
2. Input parameters and triggers
3. Job-by-job walkthrough with diagrams
4. Artifact flow and dependencies
5. Security scanning integration
6. Troubleshooting and best practices
7. Q&A

---

## Section 1: Workflow Overview (5 minutes)

### What is Currency Build?

**Script**: 
"The Currency Build workflow is a comprehensive GitHub Actions pipeline that handles the complete lifecycle of building packages for the ppc64le architecture. Let me show you what it does:"

**[Show Diagram 1 - High-Level Overview]**

```
User Input → Build Info → Build Package → Scan Source
                ↓
         Build Wheels (5 versions) → Scan Wheels
                ↓
         Build Docker → Scan Image
                ↓
         Final Summary & Report
```

**Key Points to Emphasize**:
- Manual trigger only (`workflow_dispatch`)
- Supports multiple Python versions (3.10 through 3.14)
- Integrated security scanning (Trivy, Syft, Grype, Scancode)
- Runs on ppc64le architecture (IBM POWER)
- Produces wheels, Docker images, and comprehensive security reports

---

## Section 2: Input Parameters (5 minutes)

### Understanding the Inputs

**Script**:
"When you trigger this workflow, you'll see several input parameters. Let me explain each one:"

**[Show the GitHub Actions UI or parameter table]**

**Walk through each parameter**:

1. **package_name & version** (Required)
   - "These identify what we're building. For example: 'numpy' version '1.26.0'"

2. **validate_build_script** (Default: false)
   - "Set to 'true' to actually build the package from source"
   - "If false, we skip the build and only process metadata"

3. **wheel_build** (Default: false)
   - "Enable this to build Python wheels for all 5 Python versions"
   - "This runs in parallel for faster execution"

4. **build_docker** (Default: false)
   - "Enable if your package has a Dockerfile"
   - "Builds and scans the Docker image"

5. **Scanner flags** (enable_trivy, enable_syft, enable_grype)
   - "All default to 'true' for comprehensive security coverage"
   - "You can disable specific scanners if needed"

6. **unique_id** (Optional)
   - "Helps track builds, especially useful for retries"

7. **large-runner-label** (Optional)
   - "Use this to retrigger failed builds on more powerful runners"
   - "Options: 2xlarge or 4xlarge"

---

## Section 3: Job Flow Walkthrough (20 minutes)

### Job 1: build_info

**Script**:
"Let's start with the first job - build_info. This is the foundation of everything."

**[Show Diagram 2 - build_info Job]**

```
┌─────────────────────────────────────┐
│         build_info Job              │
├─────────────────────────────────────┤
│ 1. Checkout code                    │
│ 2. Install jq, file                 │
│ 3. Install Python deps              │
│ 4. Run read_buildinfo.sh            │
│    ├─ Parse build_info.json         │
│    └─ Extract variables             │
│ 5. Create scanner-env.sh            │
│ 6. Archive package-cache            │
│ 7. Upload artifact                  │
└─────────────────────────────────────┘
         │
         ▼
    package-cache.tar.gz
    ├─ variable.sh
    └─ scanner-env.sh
```

**Key Points**:
- "This job reads the build_info.json file from the package directory"
- "It extracts all necessary variables and creates two shell scripts"
- "These scripts are used by all subsequent jobs"
- "The package-cache artifact is the communication mechanism between jobs"

---

### Job 2: build

**Script**:
"Next is the build job, which only runs if validate_build_script is true."

**[Show Diagram 3 - build Job]**

```
┌─────────────────────────────────────┐
│           build Job                 │
├─────────────────────────────────────┤
│ Condition: validate_build_script    │
│ Runner: Dynamic (can use large)     │
├─────────────────────────────────────┤
│ 1. Download package-cache           │
│ 2. Source variables                 │
│ 3. Run build_package.sh             │
│    ├─ Clone source                  │
│    ├─ Execute build script          │
│    └─ Generate build_log            │
│ 4. Run pre_process.sh               │
│ 5. Upload build_log.gz              │
│ 6. Upload updated-package-cache     │
└─────────────────────────────────────┘
```

**Key Points**:
- "This is where the actual package compilation happens"
- "The build script is package-specific, located in the package directory"
- "Build logs are compressed and uploaded to external storage"
- "The cloned package is added to package-cache for scanners"

**Demo Tip**: "Let me show you a real build_log to see what information it contains..."

---

### Jobs 3-7: Wheel Builds (Parallel)

**Script**:
"Now we get to one of the most powerful features - parallel wheel building for multiple Python versions."

**[Show Diagram 4 - Wheel Build Jobs]**

```
┌──────────────────────────────────────────────────────────┐
│              Wheel Build Jobs (Parallel)                 │
├──────────────────────────────────────────────────────────┤
│  Condition: wheel_build == 'true'                        │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Python 3.10 │  │ Python 3.11 │  │ Python 3.12 │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                           │
│  ┌─────────────┐  ┌─────────────┐                       │
│  │ Python 3.13 │  │ Python 3.14 │  (experimental)       │
│  └─────────────┘  └─────────────┘                       │
│                                                           │
│  Each job:                                               │
│  1. Downloads package-cache                              │
│  2. Sets PYTHON_VERSION env var                          │
│  3. Runs build_wheels.sh                                 │
│  4. Uploads wheel + SHA256                               │
│  5. Uploads build log                                    │
└──────────────────────────────────────────────────────────┘
```

**Key Points**:
- "All five jobs run in parallel, saving significant time"
- "Python 3.13 and 3.14 have continue-on-error enabled - they're experimental"
- "Each wheel is uploaded independently with its SHA256 checksum"
- "Build logs are named after the wheel for easy tracking"

**Pause for Questions**: "Any questions about the wheel building process?"

---

### Job 8: wheel_licenses

**Script**:
"After all wheels are built, we scan them for license compliance."

**[Show Diagram 5 - License Scanning]**

```
┌─────────────────────────────────────┐
│      wheel_licenses Job             │
├─────────────────────────────────────┤
│ Condition: always() && wheel_build  │
│ Depends on: All wheel_build jobs    │
├─────────────────────────────────────┤
│ 1. Download all wheels              │
│ 2. Run scancode_wheel_scan.sh       │
│    └─ Scans each wheel              │
│ 3. Collect *_output.json files      │
│ 4. Upload wheel_scanner.tar.gz      │
└─────────────────────────────────────┘
```

**Key Points**:
- "Uses Scancode toolkit for license detection"
- "Runs even if some wheel builds fail (always() condition)"
- "Produces JSON output for each wheel"

---

### Job 9: wheel_scanner

**Script**:
"We also scan wheels for security vulnerabilities using Grype."

```
┌─────────────────────────────────────┐
│       wheel_scanner Job             │
├─────────────────────────────────────┤
│ Condition: always() && wheel_build  │
│ Depends on: All wheel_build jobs    │
├─────────────────────────────────────┤
│ 1. Download all wheels              │
│ 2. Run grype_wheel_scan.sh          │
│    └─ Vulnerability scanning        │
│ 3. Collect scan results             │
│ 4. Upload grype_wheel_scanner.tar.gz│
└─────────────────────────────────────┘
```

**Key Points**:
- "Grype checks for known vulnerabilities in wheel dependencies"
- "Complements the source code scanning"

---

### Job 10: source_scanner

**Script**:
"This is where we scan the source code itself with three different tools."

**[Show Diagram 6 - Source Scanning]**

```
┌─────────────────────────────────────────────────────┐
│            source_scanner Job                       │
├─────────────────────────────────────────────────────┤
│ Condition: validate_build_script == 'true'          │
│ Depends on: build job                               │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────┐                               │
│  │  Trivy Scan      │  (if enable_trivy)            │
│  ├──────────────────┤                               │
│  │ • Vulnerabilities│                               │
│  │ • SBOM (CycloneDX)│                              │
│  └──────────────────┘                               │
│                                                      │
│  ┌──────────────────┐                               │
│  │  Syft Scan       │  (if enable_syft)             │
│  ├──────────────────┤                               │
│  │ • SBOM (JSON)    │                               │
│  └──────────────────┘                               │
│                                                      │
│  ┌──────────────────┐                               │
│  │  Grype Scan      │  (if enable_grype)            │
│  ├──────────────────┤                               │
│  │ • Vulnerabilities│                               │
│  │ • SBOM (JSON)    │                               │
│  └──────────────────┘                               │
│                                                      │
│  Output: source_scanner.tar.gz                      │
└─────────────────────────────────────────────────────┘
```

**Key Points**:
- "Three complementary tools for comprehensive coverage"
- "Trivy: Fast, comprehensive vulnerability database"
- "Syft: Excellent SBOM generation"
- "Grype: Vulnerability matching from Anchore"
- "All results are aggregated into one archive"

---

### Jobs 11-12: Docker Build & Scan

**Script**:
"If the package includes a Docker image, we build and scan it."

**[Show Diagram 7 - Docker Pipeline]**

```
┌─────────────────────────────────────┐
│       build_docker Job              │
├─────────────────────────────────────┤
│ Condition: build_docker == 'true'   │
├─────────────────────────────────────┤
│ 1. Download package-cache           │
│ 2. Run build_docker.sh              │
│ 3. Save image as image.tar          │
│ 4. Upload Docker image              │
│ 5. Upload package-cache-with-image  │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│       image_scanner Job             │
├─────────────────────────────────────┤
│ 1. Download package-cache-with-image│
│ 2. Load Docker image                │
│ 3. Run Trivy image scan             │
│ 4. Run Syft image scan              │
│ 5. Run Grype image scan             │
│ 6. Upload image_scanner.tar.gz      │
└─────────────────────────────────────┘
```

**Key Points**:
- "Docker image is saved as a tar file for scanning"
- "Same three scanners used for consistency"
- "Image scanning catches vulnerabilities in base images and layers"

---

### Job 13: final_summary

**Script**:
"Finally, we aggregate everything and generate a comprehensive report."

**[Show Diagram 8 - Final Summary]**

```
┌─────────────────────────────────────────────────────┐
│            final_summary Job                        │
├─────────────────────────────────────────────────────┤
│ Condition: build & source_scanner success           │
│ Depends on: All major jobs                          │
├─────────────────────────────────────────────────────┤
│ 1. Create Python venv                               │
│ 2. Install dependencies                             │
│    • requests                                       │
│    • xlsxwriter                                     │
│    • packaging                                      │
│ 3. Run run_currency_processor                       │
│    ├─ Aggregates all scan results                   │
│    ├─ Generates Excel reports                       │
│    ├─ Creates summary statistics                    │
│    └─ Uploads to external storage                   │
└─────────────────────────────────────────────────────┘
```

**Key Points**:
- "This is where all the pieces come together"
- "Generates Excel reports for easy review"
- "Only runs if core jobs succeed"
- "Results are uploaded to external storage for long-term retention"

---

## Section 4: Artifact Flow (5 minutes)

### Understanding Artifact Dependencies

**Script**:
"Let me show you how artifacts flow between jobs. This is crucial for understanding the pipeline."

**[Show Diagram 9 - Artifact Flow]**

```
┌─────────────┐
│ build_info  │
└──────┬──────┘
       │
       │ package-cache.tar.gz
       │ ├─ variable.sh
       │ └─ scanner-env.sh
       │
       ├──────────────────────────────────────┐
       │                                       │
       ▼                                       ▼
┌─────────────┐                      ┌──────────────┐
│    build    │                      │ wheel_builds │
└──────┬──────┘                      └──────┬───────┘
       │                                     │
       │ updated-package-cache               │ individual wheels
       │ ├─ variable.sh                      │ + SHA256 checksums
       │ ├─ scanner-env.sh                   │
       │ └─ cloned_package/                  │
       │                                     │
       ▼                                     ▼
┌─────────────┐                      ┌──────────────┐
│source_scanner│                     │wheel_scanners│
└─────────────┘                      └──────────────┘
       │                                     │
       └──────────────┬──────────────────────┘
                      │
                      ▼
              ┌──────────────┐
              │final_summary │
              └──────────────┘
```

**Key Points**:
- "package-cache is the central communication mechanism"
- "It gets enriched as it flows through the pipeline"
- "Each job downloads what it needs and uploads what others need"
- "This design allows for parallel execution where possible"

---

## Section 5: Security Scanning Deep Dive (5 minutes)

### Why Multiple Scanners?

**Script**:
"You might wonder why we use three different scanners. Let me explain the rationale."

**[Show Comparison Table]**

```
┌──────────┬─────────────┬──────────────┬─────────────┐
│ Scanner  │ Strength    │ Focus        │ Output      │
├──────────┼─────────────┼──────────────┼─────────────┤
│ Trivy    │ Speed       │ CVE database │ Vuln + SBOM │
│          │ Comprehensive│ Multi-format │ CycloneDX   │
├──────────┼─────────────┼──────────────┼─────────────┤
│ Syft     │ SBOM detail │ Dependency   │ SBOM JSON   │
│          │ Accuracy    │ mapping      │             │
├──────────┼─────────────┼──────────────┼─────────────┤
│ Grype    │ Precision   │ Vulnerability│ Vuln + SBOM │
│          │ Low false + │ matching     │ JSON        │
└──────────┴─────────────┴──────────────┴─────────────┘
```

**Key Points**:
- "Each scanner has different vulnerability databases"
- "Using multiple scanners reduces false negatives"
- "Different SBOM formats for different compliance needs"
- "Scancode specifically for license compliance"

---

## Section 6: Troubleshooting (5 minutes)

### Common Issues and Solutions

**Script**:
"Let me share some common issues you might encounter and how to resolve them."

### Issue 1: Build Timeout

**Symptoms**: Job times out after 6 hours

**Solution**:
```
1. Retrigger with large-runner-label
2. Options:
   - ubuntu-24.04-ppc64le-2xlarge-p10
   - ubuntu-24.04-ppc64le-4xlarge-p10
3. Keep same unique_id for tracking
```

### Issue 2: Wheel Build Fails for Specific Python Version

**Symptoms**: One Python version fails, others succeed

**Solution**:
```
1. Check wheel build log for that version
2. Common causes:
   - Missing dependencies for that Python version
   - Incompatible C extensions
   - Python version-specific syntax
3. Python 3.13/3.14 failures are expected (experimental)
```

### Issue 3: Scanner Fails

**Symptoms**: Scanner job fails with network or database errors

**Solution**:
```
1. Check scanner-specific logs
2. Common causes:
   - Vulnerability database update in progress
   - Network connectivity issues
   - Scanner tool version mismatch
3. Retrigger the workflow
```

### Issue 4: Missing build_info.json

**Symptoms**: build_info job fails immediately

**Solution**:
```
1. Verify build_info.json exists in package directory
2. Check JSON syntax is valid
3. Ensure required fields are present:
   - package_name
   - version
   - package_dir
```

---

## Section 7: Best Practices (5 minutes)

### Recommendations for Success

**Script**:
"Based on our experience, here are the best practices I recommend:"

### 1. Always Use unique_id

```yaml
unique_id: "build-2026-06-20-001"
```

**Why**: 
- Tracks builds across retries
- Easier to correlate logs and artifacts
- Helps with debugging

### 2. Enable All Scanners Initially

```yaml
enable_trivy: true
enable_syft: true
enable_grype: true
```

**Why**:
- Comprehensive security coverage
- Different scanners catch different issues
- Better compliance posture

### 3. Review Scanner Results

**Process**:
1. Download scanner archives from external storage
2. Review vulnerability reports
3. Prioritize critical/high severity issues
4. Track remediation in your issue tracker

### 4. Use Large Runners Proactively

**When to use**:
- Packages with heavy compilation (e.g., numpy, scipy)
- Packages with large test suites
- Known memory-intensive builds

### 5. Monitor Build Logs

**What to check**:
- Compilation warnings
- Test failures
- Dependency resolution issues
- Scanner warnings

### 6. Keep build_info.json Updated

**Required fields**:
```json
{
  "package_name": "numpy",
  "version": "1.26.0",
  "package_dir": "n/numpy",
  "wheel_build": true,
  "docker_build": false
}
```

---

## Section 8: Comparison with PR Build (3 minutes)

### Currency Build vs PR Build

**Script**:
"We also have a PR Build workflow. Let me quickly explain the differences."

**[Show Comparison]**

```
┌─────────────────┬──────────────────┬─────────────────┐
│ Aspect          │ Currency Build   │ PR Build        │
├─────────────────┼──────────────────┼─────────────────┤
│ Trigger         │ Manual           │ Pull Request    │
│ Purpose         │ Production build │ Validation      │
│ Wheel Upload    │ Yes              │ No              │
│ Docker Upload   │ Yes              │ No              │
│ Scanner Upload  │ Yes              │ No              │
│ Changed Files   │ N/A              │ Conditional     │
│ Final Summary   │ Yes              │ No              │
└─────────────────┴──────────────────┴─────────────────┘
```

**Key Points**:
- "PR Build validates changes before merge"
- "Currency Build creates production artifacts"
- "PR Build is more selective based on changed files"
- "Both share similar structure and scripts"

---

## Section 9: Q&A (5-10 minutes)

### Common Questions

**Script**:
"Now I'd like to open the floor for questions. Here are some I commonly get:"

### Q1: How long does a typical build take?

**A**: 
- "Without wheels: 30-45 minutes"
- "With wheels: 1.5-2 hours (parallel execution)"
- "With Docker: Add 20-30 minutes"

### Q2: Where are artifacts stored?

**A**:
- "GitHub Actions artifacts: 90 days retention"
- "External storage: Permanent (via upload scripts)"
- "Access via currency service API"

### Q3: Can I run this locally?

**A**:
- "Scripts can run locally on ppc64le systems"
- "GitHub Actions-specific features won't work"
- "Use for testing script changes"

### Q4: How do I add a new Python version?

**A**:
```yaml
1. Copy existing wheel_build_py3XX job
2. Update PYTHON_VERSION
3. Update job name
4. Add to final_summary dependencies
5. Test thoroughly
```

### Q5: What if a scanner reports false positives?

**A**:
- "Review the vulnerability details"
- "Check if it applies to your use case"
- "Document exceptions in your security policy"
- "Consider suppression files for scanners"

---

## Closing (2 minutes)

### Summary

**Script**:
"Let me summarize what we've covered today:"

**Key Takeaways**:
1. Currency Build is a comprehensive pipeline for ppc64le packages
2. It handles building, wheel creation, Docker images, and security scanning
3. Multiple scanners provide defense in depth
4. Artifacts flow through jobs via package-cache
5. Large runners available for resource-intensive builds
6. Always review scanner results and build logs

### Resources

**Available Documentation**:
- Full workflow documentation: `docs/currency-build-workflow-kt.md`
- Script reference: `gha-script/README.md` (if exists)
- Workflow file: `.github/workflows/currency-build.yaml`

### Next Steps

**For the Team**:
1. Review the documentation
2. Try triggering a test build
3. Examine the artifacts and logs
4. Set up notifications for build failures
5. Integrate scanner results into your security workflow

### Contact

**Script**:
"If you have any questions after this session, please reach out to the build engineering team. Thank you for your time!"

---

## Appendix: Quick Reference Commands

### Triggering a Build

```bash
# Via GitHub CLI
gh workflow run currency-build.yaml \
  -f package_name=numpy \
  -f version=1.26.0 \
  -f validate_build_script=true \
  -f wheel_build=true \
  -f build_docker=false \
  -f unique_id=test-build-001
```

### Downloading Artifacts

```bash
# Via GitHub CLI
gh run download <run-id> -n package-cache
gh run download <run-id> -n updated-package-cache
```

### Checking Build Status

```bash
# Via GitHub CLI
gh run list --workflow=currency-build.yaml
gh run view <run-id>
gh run view <run-id> --log
```

---

**Script Version**: 1.0  
**Last Updated**: 2026-06-20  
**Presenter**: Build Engineering Team