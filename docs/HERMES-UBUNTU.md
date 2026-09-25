# OJA-T Ubuntu + Hermes development handoff

Use this environment to reproduce and extend the OJA-T implementation locally with Hermes Agent. Keep secrets out of Git.

## Clone

```bash
git clone https://github.com/Samoolino/OJA-T.git ~/src/OJA-T
cd ~/src/OJA-T
git checkout main
git pull --ff-only
```

## Ubuntu prerequisites

```bash
sudo apt-get update
sudo apt-get install -y git curl xz-utils build-essential libpq-dev postgresql-client redis-tools
```

## Hermes Agent

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
hermes doctor
hermes model
hermes tools
```

Hermes keeps secrets in `~/.hermes/.env` and normal configuration in `~/.hermes/config.yaml`; neither belongs in Git.

## Repository bootstrap

```bash
if [ -f .ruby-version ]; then cat .ruby-version; fi
ruby --version
bundle --version
bundle config set --local path vendor/bundle
bundle install
```

If the repository defines its own database/bootstrap instructions, follow those before running the transaction tests. PostgreSQL and Redis should be available locally when required by the test suite.

## Agent handoff prompt

```text
Work in ~/src/OJA-T. Inspect the current git status, current branch, recent commits, CI configuration, and G2 transaction tests before modifying code. Reproduce the existing G2 result locally. Make evidence-based, minimal changes, run the affected tests, then the full G2 suite. Do not claim certification without passing test evidence. Preserve parity with OJa-WA at the externally observable transaction boundaries while retaining OJA-T's implementation architecture.
```
