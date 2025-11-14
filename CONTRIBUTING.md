# Contributing to WVS Contracts

Thank you for your interest in contributing to WVS Contracts! This document outlines our contribution workflow.

## Workflow: Issue → Pull Request

We follow a structured workflow to ensure all changes are properly tracked and reviewed:

### 1. Create an Issue First

**Before making any changes**, please create an issue describing:
- What you want to change or add
- Why this change is needed
- Any relevant context or background

This helps us:
- Track all work being done
- Discuss the approach before implementation
- Avoid duplicate work
- Maintain a clear history of decisions

### 2. Create a Pull Request

Once you have an issue:

1. **Create a branch** from `main`:
   ```bash
   git checkout main
   git pull upstream main
   git checkout -b issue-<number>-<short-description>
   ```

2. **Make your changes** and commit them:
   ```bash
   git add .
   git commit -m "fix: description (closes #<issue-number>)"
   ```

3. **Push to your fork**:
   ```bash
   git push origin issue-<number>-<short-description>
   ```

4. **Create a Pull Request**:
   - Link your PR to the issue using keywords like `closes #<issue-number>` or `fixes #<issue-number>` in the PR description
   - Ensure your PR description clearly explains what changes were made and why
   - Reference the original issue number

### 3. PR Review Process

- All PRs require review before merging
- Ensure CI checks pass (tests, formatting, build)
- Address any review comments
- Once approved, maintainers will merge the PR

## Branch Naming Convention

Use descriptive branch names that reference the issue:
- `issue-123-add-feature-x`
- `issue-456-fix-bug-y`
- `feat/issue-789-implement-z`

## Commit Messages

Follow conventional commit format:
- `feat: add new feature (closes #123)`
- `fix: resolve bug in contract (fixes #456)`
- `docs: update README (closes #789)`
- `test: add tests for feature (closes #123)`

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone git@github.com:YOUR_USERNAME/wvs-contracts.git
   cd wvs-contracts
   git remote add upstream https://github.com/wvs-finance/wvs-contracts.git
   ```

3. Install dependencies:
   ```bash
   forge install
   ```

4. Run tests:
   ```bash
   forge test
   ```

5. Format code:
   ```bash
   forge fmt
   ```

## Important Notes

- **Do not commit directly to `main`** - all changes must go through PRs
- **Always create an issue first** before starting work
- **Link your PR to the issue** using GitHub keywords (`closes`, `fixes`, `resolves`)
- Ensure all tests pass before submitting a PR
- Follow the existing code style and formatting

## Repository Administrators

To enforce this workflow at the repository level:

1. **Enable branch protection rules** for `main`:
   - Go to Settings → Branches → Add rule
   - Branch name pattern: `main`
   - Require pull request reviews before merging
   - Require status checks to pass before merging (select CI checks)
   - Do not allow bypassing the above settings

2. **Configure issue templates** (already included in `.github/ISSUE_TEMPLATE/`)

3. **PR validation workflow** (already configured in `.github/workflows/pr-validation.yml`) will warn if PRs aren't linked to issues

## Questions?

If you have questions about the contribution process, please open an issue or reach out to the maintainers.

