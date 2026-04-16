# AI Agents Guidelines

This document provides instructions for AI Agents working with the implementations of this Terraform module template.

## Template Guidelines
- **Avoid In place Modification** for implementations terraform-module-template is a template repository should not contain implementations.
- **Use Separate Repository for Implementations**: Implementations should be stored in separate repositories to maintain modularity and version control.
  - New repositories should be named in a way that reflects their purpose and functionality, prefixed with `terraform-module-` followed by the cloud provider (e.g., `terraform-module-aws`, `terraform-module-gcp`, `terraform-module-azurerm`).
  - This template repository should be used as a boilerplate for new implementations.
  - Use GitHub Flow way of work for template and implementation repositories.
- **Supported Providers**:
 - AWS
 - GCP
 - Azure
 - MongoDB Atlas
 - Github


## Implementation Repository Guidelines

- **Use make as been provided**: All commands should be run from the root of the repository.
- **Avoid to modify**: Avoid modifying the following: 
  - Any files originating from the cloud provider boilerplate (e.g., `aws.tf`, `google.tf`, `azurerm.tf`, `variables-azurerm.tf`, `locals.tf`) in `.cloudopsworks/boilerplate/` (except `versions.tf`).
  - Anything under `.cloudopsworks/boilerplate/`
  - `locals-vars.tf`, `variables.tf`, `AGENTS.md`, `CLAUDE.md`, `.github/**`, `Makefile`, `.gitignore`, `gitversion.yaml`
- **Use variables-module.tf**:
  - Rename the word `module` in `variables-module.tf` with a proper subname depending on the purpose of this module.
  - The subname must be no more than 12 chars (e.g., `variables-vpc.tf`).
- **Initialization**:
  - This template must be initialized on the target cloud provider using `Makefile`.
  - For AWS: `make init/aws`
  - For GCP: `make init/gcp`
  - For Azure: `make init/azurerm`
  - For MongoDB Atlas: `make init/mongodb`
  - For Github: `make init/github`
  - The initialization process for each cloud will copy its boilerplate files to the root module.
  - If a `versions.tf` file exists (e.g., from `.cloudopsworks/boilerplate/aws`, `gcp`, `azurerm`, or any other supported provider), the module is already initialized and under development.
  - You can check the current provider in `.cloudopsworks/.provider`.
  - You can modify `versions.tf` to include additional providers to help with the resolution of your task.
- **Avoid creating spurious configuration files**:
    - Do not create any configuration files that are not required for the task at hand.
    - Only create files that are necessary for the specific functionality being implemented.
    - Do not create provider files or provider initialization implementation at all.
- **Locals management**:
  - Do not create local variables that are not used in the module.
  - Keep local variable names descriptive and consistent with the module's purpose.
  - Use locals to encapsulate complex expressions and improve readability.
- **Documentation**: See [Documentation Guidelines](#documentation-guidelines) section below.
- **Variables**:
  - Honor structured variables instead of lots of simple variables.
  - Prefer to have a single settings variable for simplicity and maintainability.
  - Use descriptive variable names that reflect their purpose.
  - Avoid using magic numbers and constants directly in code.
- **Mandatory Header**: Each .tf file must start with the following copyright header:
  ```hcl
  ##
  # (c) 2021-2026
  #     Cloud Ops Works LLC - https://cloudops.works/
  #     Find us on:
  #       GitHub: https://github.com/cloudopsworks
  #       WebSite: https://cloudops.works
  #     Distributed Under Apache v2.0 License
  #
  ```
- **Formatting, Validation & Linting**:
  - Formatting: `make fmt`
  - Validation & Linting: `make lint`
- **Repository Management**
  - Use process as described in the contributing guidelines: [GitHub Flow](https://cloudopsworks.co/resources/githubflow-way-of-work/)


## Versioning Management

Module versioning follows GitHub Flow — a simplified branching model where feature branches are created from and merged back into `master`. Use `make` targets whenever available for branch and release operations.

### General Rules

- **Never push directly to `master`**. All changes must flow through feature or hotfix branches and be merged via pull requests.
- Branches must be created before any change is committed.
- Follow [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`) for all module tags.
- There is no `develop` branch — all work flows directly through feature branches to `master`. This approach simplifies the development workflow and enables continuous integration and deployment from the main branch.
- Avoid in the commit comments explicitly mentioning `+semver:` changes within changesets, describe it with other words. The semver annotations should only be present in commit messages and PR descriptions to trigger the correct version bump in CI.
- Avoid scrubbing into Makefile or tronador utility scripts.
- Use `make` targets whenever available for branch and release operations.
- Use `gh` cli for PR merging and release management.
  - When waiting for a PR status check to pass, use `gh pr checks <number> --watch`
- Plan consistently and thoroughly before starting any work.

### Semver Commit Annotations

To trigger the correct version bump in CI, include a semver annotation in your commit message or PR description:

| Change Type             | Annotation keywords                                           |
|-------------------------|---------------------------------------------------------------|
| Major / breaking change | `+semver: major`                                              |
| Minor / feature change  | `+semver: minor` or `+semver: feature` or `+semver: breaking` |
| Fix / patch change      | `+semver: fix` or `+semver: patch`                            |

Example commit messages:
```
feat: add support for VPC endpoints +semver: minor
fix: correct IAM policy ARN +semver: fix
refactor!: remove deprecated outputs +semver: breaking
```

### New Module Features and Provider Version Upgrades

All new features and provider version upgrades branch directly from `master` using the no-develop targets:

1. Create a feature branch from `master`:
   ```sh
   make gitflow/feature/start-no-develop:<feature-name>
   ```
2. Implement changes and validate:
   ```sh
   make fmt
   make lint
   ```
3. Finish the feature — this merges it back into `master` via pull request:
   ```sh
   make gitflow/feature/finish-no-develop:<feature-name>
   ```

For provider upgrades, increment the semver digit accordingly: **MAJOR** for breaking provider changes (e.g., AWS `4.x` → `5.x`), **MINOR** for backwards-compatible upgrades.

### Workflow Version Upgrades and Documentation Fixes (Patch)

Workflow upgrades and documentation-only fixes are patch-level changes and use the **hotfix** branch type, not feature branches:

1. Start a hotfix branch from `master`:
   ```sh
   make gitflow/hotfix/start
   ```
2. Apply changes (run `make repos/upgrade` for template upgrades, then update docs as needed):
   ```sh
   make repos/upgrade   # pulls latest template version
   # edit .boilerplate/inputs.yaml, README.yaml, etc.
   make readme          # regenerate README.md last
   ```
3. Commit using conventional commits with `+semver: patch`:
   ```sh
   git commit -m "docs: sync inputs.yaml and update docs +semver: patch"
   ```
4. **Publish first**, then finish — the finish step requires the branch to exist on the remote:
   ```sh
   make gitflow/hotfix/publish   # push branch to remote (required before finish)
   make gitflow/hotfix/finish    # creates the PR
   ```
5. Wait for all CI checks to pass, then merge with `gh` CLI (see [PR Merge Guidelines](#pr-merge-guidelines)).

### PR Merge Guidelines

After all CI checks pass, merge using `gh pr merge` with a proper merge commit:

```sh
gh pr merge <PR_NUMBER> --repo <owner/repo> --merge \
  --subject "chore: merge <branch> - <short description> +semver: patch" \
  --body "$(cat <<'EOF'
## Summary

- Bullet point summary of changes

+semver: patch
EOF
)" --delete-branch=false
```

Key rules:
- Always use `--merge` (never `--squash` or `--rebase`) to preserve commit history.
- Include `+semver: <level>` in the **body** (not just the title) so GitVersion picks it up.
- Use `--delete-branch=false` when you only want to delete the local branch (do so separately with `git branch -d <branch>`).
- After merge, checkout and pull master: `git checkout master && git pull origin master`.

### Summary Table

| Change Type                             | Branch Type | Merges Into | Semver Impact | Annotation                          |
|-----------------------------------------|-------------|-------------|---------------|-------------------------------------|
| Workflow version upgrade (patch)        | `hotfix`    | `master`    | PATCH         | `+semver: patch`                    |
| Workflow version upgrade (minor/major)  | `feature`   | `master`    | MINOR         | `+semver: patch`                    |
| Documentation fix / inputs.yaml sync    | `hotfix`    | `master`    | PATCH         | `+semver: patch`                    |
| Provider major version upgrade          | `feature`   | `master`    | MAJOR         | `+semver: breaking`                 |
| Provider minor/patch version upgrade    | `feature`   | `master`    | MINOR / PATCH | `+semver: minor` / `+semver: patch` |
| New module feature                      | `feature`   | `master`    | MINOR         | `+semver: feature`                  |
| Bug fix                                 | `feature`   | `master`    | PATCH         | `+semver: fix`                      |
| Breaking / incompatible change          | `feature`   | `master`    | MAJOR         | `+semver: breaking`                 |


## Documentation Guidelines

> Act as an expert documentation professional and Terraform/Terragrunt DevOps expert.
> Generated documentation must be human-legible; tables are encouraged for clarity.

- **Source file**: Documentation is maintained in `README.yaml`. Inner sections may use Markdown formatting.
- **Inline variable documentation**:
  - Complete inline documentation in `variables-module.tf` (or its renamed equivalent; there may be multiple `variables-*.tf` files).
  - Document each variable attribute in YAML format within the variable declaration block.
  - After each attribute, add a comment indicating whether it is `(Required)` or `(Optional)`, a short description, and the default value when applicable. Example:
    ```yaml
    id: "sampleid"   # (Required) Unique identifier for the resource.
    ```
    - If the attribute is a complex object, document as a YAML block before the variable declaration as commented lines.
    - For attributes that accept a predefined set of values (e.g., `state` with possible values `present` or `absent`), include a comment listing the valid options.
    - Description must contain the marker of optionality and default value. Avoid embedding complex YAML descriptions, make a general description, then add the specifics in the comments.
  - Infer and document the possible values for each attribute using the upstream Terraform provider documentation as the source.
- **README.yaml fields**: Once inline documentation is complete, update `README.yaml` to properly document the following fields:
  - `name`
  - `description`
  - `introduction`
  - `usage` — write examples using Terragrunt HCL; avoid plain Terraform HCL. Include all module variables with their full inline-documented YAML structure.
  - `examples` and `quickstart`
- **Updates**: Apply the same criteria above whenever new variables or resources are added to the module.
  - copyrights.year: if not specified or blank, set "2021", should be an year not a range, if there is a year specified leave it as is.
  - badges: adjust the badge.image links to point to the correct repository (owner/repo).
- **README.md generation**: Run `make readme` as the **last step** after all documentation updates are complete.

### `.boilerplate/inputs.yaml` Guidelines

The `.boilerplate/inputs.yaml` file is the per-deployment configuration file loaded by `terragrunt.hcl` as `local.local_vars`. It must be kept in sync with the module's `variables-*.tf` files and serve as self-documenting configuration for operators.

- **Scope**: Include **all** module-specific variables — those defined in `variables-module.tf` (or its renamed equivalent variables-*.tf).
  - Include **both scalar top-level variables** (e.g., `name`, `name_prefix`, `project_id`, `run_hoop`) **and** complex object variables (e.g., `settings`). A common mistake is to only document the complex object and forget the plain scalars.
  - Do **not** include variables that the Terragrunt hierarchy supplies automatically:
    - `is_hub` — injected by the boilerplate/template engine
    - `spoke_def` — sourced from `spoke-inputs.yaml`
    - `org` — sourced from `env-inputs.yaml`
    - `extra_tags` — built from merged tag files
- **Comment format**: Mirror the `(Required)` / `(Optional)` YAML comment style used in `variables-*.tf`. For every key, add an inline comment with:
  - Whether it is required or optional
  - A short description
  - The default value and any notes on valid values or format
  - Example values where helpful
- **Complex objects**: Expand all sub-keys of object variables (e.g., `settings`) as commented lines, even when the default is `{}`. This makes all available options visible to the operator without them needing to read the Terraform source.
- **Module transformations**: If the module transforms an input value before passing it to the provider (e.g., converting a region string to uppercase-underscore format for the Atlas API), document both the expected input format and the resulting API value in the comment.
- **Sync on change**: Whenever a variable is added, removed, or modified in `variables-*.tf`, update `.boilerplate/inputs.yaml` accordingly in the same commit.