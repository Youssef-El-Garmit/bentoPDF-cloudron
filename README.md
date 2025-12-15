# cloudron-bentopdf
Package for deployment of BentoPDF on Cloudron

## About

This is a Cloudron package for [BentoPDF](https://github.com/alam00000/bentopdf), a privacy-first PDF toolkit that runs entirely in your browser. All PDF processing happens client-side, ensuring your documents never leave your device.

## Deployment

To deploy it manually on Cloudron, follow these instructions:

### Build the Docker Image:
~~~
docker build -t APPNAME .
~~~

### Tag the Docker Image:
~~~
docker tag APPNAME:latest URL-OF-YOUR-IMAGE-REGISTRY/APPNAME
~~~

### Push Image to registry:
~~~
docker push URL-OF-YOUR-IMAGE-REGISTRY/APPNAME
~~~

### Install image on your Cloudron Instance:
~~~
cloudron install --image URL-OF-YOUR-IMAGE-REGISTRY/APPNAME
~~~

## Features

BentoPDF provides a comprehensive set of PDF tools:
- Merge, split, rotate, and organize PDFs
- Convert images to PDF and PDF to images
- Add watermarks, signatures, and page numbers
- Compress PDFs
- Fill PDF forms
- Extract text and metadata
- Password protection
- And much more!

All processing happens in your browser - no server-side processing required.

## License

This project is under the [GNU GPLv3](LICENSE).

BentoPDF itself is licensed under [AGPL-3.0](https://github.com/alam00000/bentopdf/blob/main/LICENSE).

