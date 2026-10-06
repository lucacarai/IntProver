# Deployment and source distribution

Prepared on 5 October 2026 using the GitHub Pages workflow described in the supplied Correct Partition guide. The prover stays a static browser application; React and Vite are not required by this app.

## Repository and website location

The user selected the new repository `lucacarai/IntProver` and will upload and publish it personally. Its intended Pages URL is https://lucacarai.github.io/IntProver/. Do not reuse the Correct-partition repository for this application. No repository creation, upload, or publication has been performed by the assistant.

The files use relative URLs, including the worker, Prolog source, runtime assets, and license/source links. The same `dist/` folder can be hosted at a domain root or beneath a GitHub Pages repository subfolder without hard-coding its name. Open the project URL with a trailing slash.

## Local verification

Use Node.js 24 (the workflow's version). No system Prolog installation is needed.

1. `npm ci`
2. `npm test`
3. `npm run build`
4. `npm run preview`

The preview is at http://127.0.0.1:4174/prover/ and serves only generated static files. This checks the same subfolder behavior needed by GitHub Pages. If npm is unavailable, the commands are `node --test tests/*.test.mjs`, `node scripts/build.mjs`, and `node scripts/preview.mjs`.

Verify a valid formula, an invalid formula and its countermodel, the explicit grouping preview, malformed-input handling, the source download, and the attribution/license page. Check that `p or neg p` displays labelled colored worlds and `p and q and r imp s` displays a monochrome diagram. Editing a formula must clear its old diagram. Optionally run `npm run licenses` to inspect licenses registered in the pinned runtime.

## GitHub Pages

1. Create or choose a repository for this app. A public repository makes the source accessible and works with GitHub Pages on a free account.
2. Commit the project source and vendor/package runtime to its `main` branch. Do not commit `dist/`, screenshots, credentials, or machine-specific files. `.gitignore` excludes build output and previews.
3. In Settings → Pages, set the publishing source to **GitHub Actions**.
4. Push `main` or run the Deploy theorem prover to GitHub Pages workflow manually.
5. The workflow checks out source, sets up Node.js 24, runs `npm ci`, tests the prover, builds `dist/`, configures Pages, uploads the artifact, and deploys it.
6. Check the Actions result, then open the published project URL and verify formulas and license/source links again.

The application requires no running Node.js server on GitHub Pages. `server.mjs` is only for local development. Publishing this Pages app does not itself add a link or iframe to a separate personal website.

## Publish from the working folder using GitHub Desktop

Use the same folder in which the assistant edits the app:

`C:\Users\carai\Documents\AI projects W\fCubeRemastered`

There is no need to extract or upload the project ZIP for this workflow. The local folder can remain named `fCubeRemastered` while the repository on GitHub is named `IntProver`.

1. Create a local Git repository in this existing folder through GitHub Desktop. In File → New repository, use **Name: fCubeRemastered** and **Local path: C:\Users\carai\Documents\AI projects W**. The resulting repository path must be the existing working folder above, not a new nested folder. Leave README initialization off and Git ignore and License set to None, because the project already contains these files.
2. Ensure the current branch is named `main`. If needed, use Branch → Rename to change the initial branch name before publishing.
3. Review the changed files in GitHub Desktop, enter a summary such as `Initial IntProver application`, and click **Commit to main**. Include the source, original fCube directory, bundled runtime, licenses, and `.github/workflows/deploy.yml`. The provided `.gitignore` excludes generated files and the ZIP package.
4. Click **Publish repository**. Set the GitHub repository name to **IntProver**, publish under your personal account **lucacarai**, and uncheck **Keep this code private**. Then publish. Changing the name in this dialog does not require renaming the local working folder.
5. On GitHub, set Settings → Pages → Build and deployment → Source to **GitHub Actions**.
6. Open Actions → Deploy theorem prover to GitHub Pages → Run workflow and run it on `main`. This is useful if the first push triggered the workflow before Pages was enabled.
7. Wait for the build and deploy jobs to succeed, then open https://lucacarai.github.io/IntProver/.
8. Check `p imp p` (valid), `p or neg p` (invalid), and the footer's source download and license links.
9. Add a link to this URL on your personal website if desired. Editing that website is a separate step.

For updates, ask the assistant to edit this same working folder. Review the changes in GitHub Desktop, **Commit to main**, then **Push origin**. The included workflow tests and rebuilds the app, creates a matching source ZIP, and publishes the updated site automatically. Keep the license and attribution files in the repository; the build includes them with each published version.

GitHub Desktop references: [creating a repository](https://docs.github.com/en/desktop/overview/creating-your-first-repository-using-github-desktop) and [publishing an existing project](https://docs.github.com/en/desktop/adding-and-cloning-repositories/adding-an-existing-project-to-github-using-github-desktop).

## License materials

The build preserves the original fCube 11.1 source, GNU GPL text, original author notices and warranty disclaimer, the date and description of the adaptation, and the SWI-Prolog runtime license. All new application files are released as GPL-3.0-or-later; bundled dependencies retain their own licenses.

The footer links to `license.html` and `source.zip`. The source archive is generated from an explicit list during the same build as the website. It includes editable code, original fCube source and README, runtime package, build/test instructions and scripts, deployment workflow, and a SHA-256 file manifest. It excludes credentials and unrelated local files. Keep the source archive and GPL text accessible for every published version.

This packaging is a practical compliance approach, not a legal opinion. Before changing dependencies or licensing terms, review their applicable licenses.

## Troubleshooting

- Missing `.wasm`, `.data`, or `.pl` files: deploy the complete generated `dist/` directory and check that the site's subfolder URL ends in `/`.
- The original folder exists but `fcube.pl` is missing: build first; the build copies the original source into the static site.
- A source/license link gives 404: deploy the entire build, including `source.zip`, `LICENSE`, and `licenses/`.
- Pages workflow fails to deploy: verify Pages publishing source, repository permissions, branch protection, and the GitHub Actions log.
- Checks fail in the browser: inspect asset requests and JavaScript errors; the prover never treats a loading error or timeout as mathematical invalidity.
