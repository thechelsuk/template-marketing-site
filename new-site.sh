#!/usr/bin/env bash
# Starts a new app marketing site from this template, doing the README's steps
# in one go. Asks for each value (press Return to take the suggestion in
# brackets), shows a summary, and only changes anything once you say yes.
#
#   ./new-site.sh
#   ./new-site.sh --host tomoz.thechels.uk --name Tomoz --store-id 1234567890 \
#                 --description "See only tomorrow." [--repo uk.thechels.tomoz] [--yes]
#
# Needs: gh (signed in as thechelsuk), git, perl. Run it from anywhere; the new
# site is cloned into ~/Source/websites/<repo>.
set -euo pipefail

OWNER="thechelsuk"
TEMPLATE="$OWNER/template-marketing-site"
DEST_ROOT="${DEST_ROOT:-$HOME/Source/websites}"

HOST="" NAME="" STORE_ID="" SLUG="" DESCRIPTION="" REPO="" YES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --store-id) STORE_ID="$2"; shift 2 ;;
    --slug) SLUG="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --yes|-y) YES=1; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done

bold=$(tput bold 2>/dev/null || true); dim=$(tput dim 2>/dev/null || true); reset=$(tput sgr0 2>/dev/null || true)
ask() { # ask VAR "Question" "suggestion"
  local var="$1" q="$2" def="${3:-}" ans
  [ -n "${!var}" ] && return
  while :; do
    if [ -n "$def" ]; then read -r -p "$q ${dim}[$def]${reset}: " ans; ans="${ans:-$def}"
    else read -r -p "$q: " ans; fi
    [ -n "$ans" ] && { printf -v "$var" '%s' "$ans"; return; }
    echo "  This one's needed."
  done
}
slugify() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'; }

for tool in gh git perl; do command -v "$tool" >/dev/null || { echo "Needs $tool." >&2; exit 1; }; done
gh auth status >/dev/null 2>&1 || { echo "Sign in first: gh auth login" >&2; exit 1; }

echo "${bold}New app marketing site${reset} from $TEMPLATE"
echo
ask NAME "App name (e.g. Tomoz)"
ask HOST "Site address" "$(slugify "$NAME").thechels.uk"
ask DESCRIPTION "One sentence about the app" "$NAME for iPhone and iPad."
ask STORE_ID "App Store ID (the digits after /id in its App Store link)" "0000000000"
ask SLUG "App Store slug (the part before /id in its link)" "$(slugify "$NAME")"
ask REPO "GitHub repo name" "uk.thechels.$(slugify "${HOST%%.thechels.uk}")"

case "$STORE_ID" in *[!0-9]*) echo "The App Store ID should be digits only." >&2; exit 1 ;; esac
DEST="$DEST_ROOT/$REPO"
[ -e "$DEST" ] && { echo "$DEST already exists." >&2; exit 1; }
gh repo view "$OWNER/$REPO" >/dev/null 2>&1 && { echo "$OWNER/$REPO already exists on GitHub." >&2; exit 1; }

cat <<EOF

${bold}About to:${reset}
  1. Create ${bold}$OWNER/$REPO${reset} (public) from $TEMPLATE, cloned to $DEST
  2. Set CNAME to ${bold}$HOST${reset}
  3. Set the link checker's site_host to ${HOST//./\\.}
  4. Put $HOST in index.html, robots.txt, sitemap.xml, llms.txt and security.txt
  5. Fill in "$NAME", "$DESCRIPTION", App Store ID $STORE_ID and slug $SLUG
  6. (pages.yml only needs editing when you add files later)
  7. Point CONTRIBUTING and the issue template links at $OWNER/$REPO
  8. Turn on GitHub Pages (from Actions) with the custom domain, plus secret
     scanning, push protection and private vulnerability reporting
  Then commit and push, which deploys the site.
EOF
if [ -z "$YES" ]; then read -r -p "Go ahead? [y/N] " ok; case "$ok" in y|Y|yes) ;; *) echo "Stopped; nothing changed."; exit 0 ;; esac; fi

echo; echo "1. Creating the repo…"
gh repo create "$OWNER/$REPO" --public --template "$TEMPLATE" --description "$NAME: $DESCRIPTION" --homepage "https://$HOST" >/dev/null
for i in 1 2 3 4 5 6; do gh api "repos/$OWNER/$REPO/contents/README.md" >/dev/null 2>&1 && break; sleep 2; done
gh repo clone "$OWNER/$REPO" "$DEST" -- -q
cd "$DEST"

echo "2–7. Filling in the site…"
export HOST NAME DESCRIPTION STORE_ID SLUG REPO OWNER
HOST_RE=$(printf '%s' "$HOST" | sed 's/\./\\./g'); export HOST_RE
html() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }
HNAME=$(html "$NAME"); HDESC=$(html "$DESCRIPTION"); export HNAME HDESC
printf '%s\n' "$HOST" > CNAME
perl -pi -e 's/example\\\.thechels\\\.uk/$ENV{HOST_RE}/g' .github/workflows/link-checker.yml
perl -pi -e 's/\Qexample.thechels.uk\E/$ENV{HOST}/g' index.html robots.txt sitemap.xml llms.txt .well-known/security.txt README.md
perl -ni -e 'print unless /Replace APP_STORE_ID/' index.html
perl -pi -e 's/\QAPP_STORE_ID\E/$ENV{STORE_ID}/g; s/\QAPP_SLUG\E/$ENV{SLUG}/g; s/\QOne sentence about the app.\E/$ENV{HDESC}/g; s/\QApp name\E/$ENV{HNAME}/g' index.html
perl -pi -e 's/\QAPP_STORE_ID\E/$ENV{STORE_ID}/g; s/\QAPP_SLUG\E/$ENV{SLUG}/g; s/\QOne sentence about the app.\E/$ENV{DESCRIPTION}/g; s/\QApp name\E/$ENV{NAME}/g' llms.txt
perl -pi -e 's/\Qthechelsuk\/template-marketing-site\E/$ENV{OWNER}\/$ENV{REPO}/g' .github/CONTRIBUTING.md .github/ISSUE_TEMPLATE/config.yml
git rm -q new-site.sh
if grep -rn -E 'APP_STORE_ID|APP_SLUG|example\.thechels\.uk' --exclude-dir=.git --exclude=README.md . ; then
  echo "Some placeholders are left (above): fix them, then commit and push." >&2; exit 1
fi

git add -A
git commit -q -m "feat: $NAME's marketing site from the template" -m "Host $HOST, App Store ID $STORE_ID."
git push -q

echo "8. Turning on Pages and security…"
gh api -X POST "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 || gh api -X PUT "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null
gh api -X PUT "repos/$OWNER/$REPO/pages" -f cname="$HOST" >/dev/null || echo "  Couldn't set the custom domain yet: add $HOST in Settings → Pages once DNS is in place."
gh api -X PATCH "repos/$OWNER/$REPO" --input - >/dev/null <<JSON
{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}
JSON
gh api -X PUT "repos/$OWNER/$REPO/private-vulnerability-reporting" >/dev/null || true
gh workflow run pages.yml -R "$OWNER/$REPO" >/dev/null 2>&1 || true

cat <<EOF

${bold}Done.${reset} $NAME's site is at https://github.com/$OWNER/$REPO, in $DEST.

Still yours to do:
  • DNS: add a CNAME record ${bold}${HOST%%.thechels.uk}${reset} → ${bold}$OWNER.github.io${reset} (proxy off), then tick
    "Enforce HTTPS" in Settings → Pages once the certificate is issued.
  • Write the page: features, screenshots in images/, and styles.css colours.
  • First release: a commit whose first line is "release: first release".
EOF
