# git-keychain-secrets

My `.gitconfig` and `.nprmc` files contain secrets. The programs that read these files don't expand environment variables, so the standard techniques for removing secrets don't work. And, I don't want to encrypt the whole file, just the sensitive portions. My [dotfiles repo](https://github.com/osteele/dotfiles) therefore uses a custom [git filter](https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes), that smudges secrets from the macOS Keychain.

Configure a clone of this repository to read secrets from the Keychain thus:

On a new Mac (that doesn't have the secrets in its Keychain): create entries in the macOS Keychain:

```bash
$ security add-generic-password -U -a $USER -c gitf -C gitf -D 'git filter secret' -l GITHUB_ACCESS_TOKEN  -w …
```

Repeat for `NPM_AUTH_TOKEN` and `NPM_AUTH_SESSION`.

(`NPM_AUTH_SESSION` doesn't really need to be synced on the keychain, but npm stores it in `.npmrc` and I want to keep it out of the repo, so I'm going to war with the hammer I've got.)

On a new or old Mac: Tell git to use the filters in this repo; and apply them to the filtered files:

```bash
git config filter.secrets.smudge './filters/smudge_secrets_filter %f'
git config filter.secrets.clean './filters/clean_secrets_filter %f'
git config diff.secrets.textconv './filters/smudge_secrets_filter %f'
./scripts/resmudge-files
```

Now `git commit` will remove like-named secrets that are in the named in the `secrets` file, and `git checkout` will add them back.

This isn't a general-purpose, production-quality, solution.
It's just enough to let me add these files back to my dotfiles repo.

## Related Work

These filters differ from e.g. <http://git-secret.io> in that (1) these filters only replace the secret, not the whole file, and (2) these filters completely remove the secret (relying on its presence in another file), rather than encrypting it.