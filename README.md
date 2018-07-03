_Note: I switched from this automated approach to a manual deployment approach [here](https://github.com/blab/blotter-deploy). This repo is no longer being actively maintained._

Simple web app that:

* Listens for GitHub webhooks
* After receiving webhook, runs Git to clone or update repos on [Heroku](http://www.heroku.com/) server
* Builds website using [Jekyll](http://jekyllrb.com/)
* Pushes website to [Amazon S3](http://aws.amazon.com/s3/)
