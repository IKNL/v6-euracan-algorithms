# v6-euracan-algorithms

`VTG_PREPROCESS_MIN_RECORDS_THRESHOLD`

## Building image

Development build
```bash
make docker PKG_NAME=vtg.chisq
```

Release build (should only be triggered by CI)
```bash
make docker PKG_NAME=vtg.chisq TAG=x.x.x
```

You can also use the specialized make rules for building the image, for example:
```bash
make chisq
```
to build a development image for the `vtg.chisq` package. Or you can build a release image with:
```bash
make chisq TAG=x.x.x
```

