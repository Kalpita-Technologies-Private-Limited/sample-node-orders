#!/usr/bin/env bash
# Build, test and (cd) package one healed application on a GitHub Actions runner: the GitHub version of
# deploy/pipelines/templates/stack-build.yml. new-app-pipelines.sh --provider github copies it into the app's repo as
# .github/healer/build.sh; the toolchain (setup-dotnet / setup-node / ...) is installed by the workflow.
#
#   build.sh <pr|cd> <stack> <appFolder> <outDir> <commitSha> [solution] [publishProject] [pdbFile]
#
# cd writes the deployable package to <outDir> (with .healer-version = commit SHA, read by the smoke test).
set -euo pipefail
MODE="$1"; STACK="$2"; APP_FOLDER="${3:-.}"; OUT="$4"; SHA="$5"; SOLUTION="${6:-}"; PUBLISH="${7:-}"; PDB="${8:-}"
mkdir -p "$OUT"
cd "$APP_FOLDER"

case "$STACK" in
  dotnet)
    dotnet restore "$SOLUTION"
    dotnet build "$SOLUTION" --configuration Release --no-restore -warnaserror /p:SourceRevisionId="$SHA"
    dotnet test "$SOLUTION" --configuration Release --no-build --logger trx --results-directory "${RUNNER_TEMP:-/tmp}/TestResults"
    if [ "$MODE" = pr ]; then dotnet format "$SOLUTION" --verify-no-changes --no-restore; fi
    if [ "$MODE" = cd ]; then
      dotnet publish "$PUBLISH" --configuration Release --no-build --output "$OUT" /p:SourceRevisionId="$SHA" \
        /p:DebugType=portable /p:CopyOutputSymbolsToPublishDirectory=true
      if [ -n "$PDB" ] && [ ! -f "$OUT/$PDB" ]; then echo "::error::$PDB missing from publish output"; exit 1; fi
    fi
    ;;
  node)
    corepack enable || true
    if   [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile
    elif [ -f yarn.lock ];      then yarn install --frozen-lockfile
    elif [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then npm ci --no-audit --no-fund
    else npm install --no-audit --no-fund; fi
    if node -e "process.exit(require('./package.json').scripts?.build ? 0 : 1)"; then npm run build; fi
    CI=true npm test
    if [ "$MODE" = cd ]; then
      if   [ -f pnpm-lock.yaml ]; then pnpm prune --prod
      elif [ -f yarn.lock ];      then yarn install --frozen-lockfile --production
      else npm prune --omit=dev; fi
      tar --exclude=.git -cf - . | tar -xf - -C "$OUT"
    fi
    ;;
  python)
    python -m pip install --upgrade pip
    reqs=""; for f in requirements.txt requirements-dev.txt requirements-test.txt dev-requirements.txt; do [ -f "$f" ] && reqs="$reqs -r $f"; done
    if [ -n "$reqs" ]; then pip install $reqs; elif [ -f pyproject.toml ]; then pip install -e ".[test]" || pip install -e .; fi
    python -c "import pytest" 2>/dev/null || pip install pytest
    python -m compileall -q -x '(^|/)(\.venv|venv|\.git)/' .
    python -m pytest -q
    if [ "$MODE" = cd ]; then
      tar --exclude=.git --exclude=__pycache__ --exclude=.venv --exclude=venv --exclude=.pytest_cache -cf - . | tar -xf - -C "$OUT"
    fi
    ;;
  java-maven|java-gradle)
    if [ "$STACK" = java-maven ]; then
      if [ -f mvnw ]; then sh mvnw -B -ntp package; else mvn -B -ntp package; fi
    else
      if [ -f gradlew ]; then sh gradlew --no-daemon build; else gradle --no-daemon build; fi
    fi
    if [ "$MODE" = cd ]; then
      jar="$(find target build/libs -maxdepth 1 -name '*.jar' 2>/dev/null | grep -v -E -- '-(sources|javadoc|plain)\.jar$|/original-' | head -n1 || true)"
      [ -n "$jar" ] || { echo "::error::No runnable jar in target/ or build/libs/"; exit 1; }
      cp "$jar" "$OUT/app.jar"
    fi
    ;;
  go)
    go vet ./...
    go test -count=1 ./...
    if [ "$MODE" = cd ]; then
      CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w -X main.version=$SHA" -o "$OUT/app" .
    fi
    ;;
  *) echo "::error::Unknown stack '$STACK'"; exit 1 ;;
esac

if [ "$MODE" = cd ]; then echo "$SHA" > "$OUT/.healer-version"; fi
