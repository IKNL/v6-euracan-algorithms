# v6-euracan-algorithms

`VTG_PREPROCESS_MIN_RECORDS_THRESHOLD`

## Building image

Development build
```bash
make docker PKG_NAME=vtg.chisq
```

Release build (should only be triggered by CI, see release section below)
```bash
make docker PKG_NAME=vtg.chisq TAG=x.x.x
```

You can also use the specialized make rules for building the image, for example:
```bash
make chisq
```
to build a development image for the `vtg.chisq` package. Or you can build a release image with (should only be triggered by CI, see release section below):
```bash
make chisq TAG=x.x.x
```

## Release
To make a release you need to tag the commit with the algorithm and version number, for example:

```bash
git tag -a [ALGORITHM]/1.0.0 -m "Release 1.0.0"
git push origin [ALGORITHM]/1.0.0
```

With `[ALGORITHM]` being the name of the algorithm:

- `chisq`
- `summary`
- `survfit`
- `coxph`

