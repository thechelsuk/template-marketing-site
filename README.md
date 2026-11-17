# template-marketing-site

A template for a new thechelsuk app marketing site on GitHub Pages. It's a
static HTML and CSS site, served as it is (`.nojekyll`, no build), with the
repo set-up already in place:

- the GitHub Pages deploy workflow (`.github/workflows/pages.yml`)
- callers of the shared [thechelsuk/workflows](https://github.com/thechelsuk/workflows):
  weekly link checker, dependency review and release
- Dependabot for GitHub Actions
- community files (code of conduct, contributing, security policy, issue and
  pull request templates), an MIT licence and `.editorconfig`
- `CNAME`, `.well-known/security.txt`, `robots.txt`, `sitemap.xml` and
  `llms.txt`

## Start a site from it

The quick way: clone this template and run its script, which asks for the app name, address and App Store ID,
then does every step below and pushes the new site:

```bash
gh repo clone thechelsuk/template-marketing-site /tmp/tms && /tmp/tms/new-site.sh
```

Or pass the values directly: `new-site.sh --name Tomoz --host tomoz.thechels.uk --store-id 1234567890
--description "See only tomorrow."` (add `--yes` to skip the confirmation). By hand, the steps are:

1. Select **Use this template** on GitHub, then **Create a new repository**.
2. Set `CNAME` to the site's host.
3. Set `site_host` in `.github/workflows/link-checker.yml` to the same host,
   with dots escaped (`example\.thechels\.uk`).
4. Replace `example.thechels.uk` in `index.html`, `robots.txt`,
   `sitemap.xml`, `llms.txt` and `.well-known/security.txt` with the host.
5. Fill in the pages: the app name, description and App Store ID
   (`APP_STORE_ID`, `APP_SLUG`) in `index.html`, then `llms.txt` and
   `styles.css`.
6. The site deploys through the shared Pages workflow (`thechelsuk/workflows`),
   which publishes every file in the repo except `.github`, dotfiles and
   README/LICENSE, so new files and folders need no workflow change.
7. Point the links in `.github/CONTRIBUTING.md` and
   `.github/ISSUE_TEMPLATE/config.yml` at the new repo.
8. In **Settings → Pages**, set the source to **GitHub Actions** and add the
   custom domain.

## Releases

Pushing a commit to `main` whose first line starts with `release:` tags a new
minor version and writes its release notes. Use `release(patch):` or
`release(major):` for other bumps. The first release is `1.0.0`.

## Licence

[MIT](LICENSE)
