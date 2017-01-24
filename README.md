### Simpla

* Author: Nicolás Schmidt <nschmidtg@gmail.com>
* Company: [Centro de Políticas Públicas de la Pontificia Universidad Católica de Chile](http://politicaspublicas.uc.cl)
* Website: [simpla.cl](https://simpla.cl)
* License: [GNU Affero GPL v3.0](LICENSE)



Based on the source code of Ollert App:
* Author: Larry Price <larry@larry-price.com>
* Company: Software Engineering Professionals, Inc.
* Website: [ollertapp.com](https://ollertapp.com)
* License: [GNU Affero GPL v3.0](LICENSE)

#### Development

You almost certainly want to be using a Unix-based operating system. Some dependencies will be necessary before you can run the application. On Ubuntu:

``` bash
# sudo apt-get install libxslt-dev libxml2-dev build-essential libqtwebkit-dev
```

*Note*: You may need more packages. If you do, please edit this document and add them to the command above.

Requirements

* `ruby-2.2.0` - Install using [RVM](https://rvm.io/), be aware of [this issue](https://rvm.io/integration/gnome-terminal)
* `mongodb` - Check out [this very helpful page](http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
* `bundler` - `gem install bundler`
* `npm` - `sudo apt-get install nodejs npm`

In the project root folder, you should:

* `bundle install`
  * Installs the required ruby gems
* `npm install`
  * Installs the required node packages

Create a file called `.env` in the root project folder. The format of the `.env` file is simply:

```
ENVIRONMENT_VARIABLE=This is the value
ANOTHER_VARIABLE=Another value
```

Environment variables:

* `PUBLIC_KEY`
  * required
  * Retrieve a public key from Trello by visiting [https://trello.com/1/appKey/generate](https://trello.com/1/appKey/generate)
* `TRELLO_TEST_DISPLAY_NAME`
  * required
  * Display name to use while running cukes (this is your `@<username>` from Trello)
* `TRELLO_TEST_USERNAME`
  * required
  * Username to use while running cukes
* `TRELLO_TEST_PASSWORD`
  * required
  * Password to use while running cukes
* `MEMBER_TOKEN`
  * required
  * this value is used to run the integration tests. To generate this value after you have entered your `PUBLIC_KEY` run the following command and paste the result into your `.env` file where it asks you to: `rake test:setup`
* `DOMAIN_FORGOT`
  * required
  * The domain of the server for redirecting. For local environment use `localhost:4000/`.
* `MAIL_FORGOT`
  * required
  * Email from where the emails will be sent.
* `PASS_FORGOT`
  * required
  * Password of the email from where the emails will be sent.
* `RACK_ENV`
  * optional
  * You should set this to `development`. Other options include `testing` and `production`.

Run `rake` to start the application on `localhost:4000`. This will fork two processes: a rack server (probably `unicorn`) and `grunt watch` (to constantly compile and minify Sass and javascript files).