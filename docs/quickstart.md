# Quick start

## Prerequisites

To get started, you will need to have
- [a google account](quickstart?id=setting-up-a-google-account)
- [a github account](quickstart?id=setting-up-a-github-account)

### Setting up a google account

You can either user a regular gmail(google) account, or you can set up a google account for your business (using a private email address hosted somewhere else different from google).

#### Creating a new account on mail-in-a-box server

If you emails are hosted using a mail-in-a-box server, you can easily create a new email using the following command to make an API call:

```bash
curl -s -X POST "https://{domain}/admin/mail/users/add" -d "email={email}" -d "password={password}" -u "{adminEmail}:{adminPassword}"
```

You can either create an account either:
- Directly
- From an invite from google workspace

##### Creating Directly
Armed with your new email account, create a youtube account using that email address. For this go to youtube, or any other Google service and click either `sign in` or if you are already logged in to Google, click your profile picture, then `switch account`, then `add account`. You should end up on the following page.

![New Account](_images/google/new_account.png 'New Account')


Click on `Create Account` and select `For work or my Business`

![New Account](_images/google/new_account_1.png 'New Account')

Create the account using your private email account for your domain.


##### Creating From Workspace Invite
Alternatively, you can create the google account through an invite from a google workspace account. With this, you will skip the step of mobile phone verification. A free workspace account can be created [here](https://workspace.google.com/essentials/). However, if you create from a workspace invite, you will not have access to `google colab`, if using free(enterprise) workspace. So you will have to remove the email from the workspace. Note that a workspace can only have emails of a single domain. You may in some instances skip the phone verification part after the account is removed from the workspace. 


### Setting up a github account

This is pretty much straight forward. Go to [GitHub](https://github.com/) and create an account.

#### Creating a Repo
Once you have your github account and you are logged in, go on to create a repo.

Click the `+` sign at the top right of the page and select `New Repository`

![New Account](_images/github/newRepo.png 'New Repo')

Enter the repo name, eg, `website`. And leave the other things as they are, and submit the form. Note down the name you have given your repo.

![New Account](_images/github/new_repo1.png 'New Repo')

## Setting Everything Up

Open [this colab notebook](https://colab.research.google.com/github/csymapp/docs2Blog/blob/master/notebooks/docs2Blog.ipynb) and sign in with your google account which you created in the previous steps.

![Run Colab](_images/colab/run_colab.png 'Run Colab')

Click the `play button` under `Website Tools` to run the notebook. Accept the requested permissions.

Then exand the notebook by clicking on the `Right Arrow` on the left of `Website Tools`

![Expand Notebook](_images/colab/colab_expand.png 'Expand Notebook')

Now follow execution by following the button below, it will move downwards once a singe cell is complete.

![Follow Execution](_images/colab/follow_colab.png 'Follow Execution')

When prompted for your email address, enter it and press enter:

![ssh key email](_images/colab/colab_enter_email.png 'ssh key email')


### Setting up ssh keys in GitHub

If you have reached this part, you are almost done. The next step step is to set up ssh keys in github. For this, follow these steps:

1. Go to github.com (you should be already logged in already.) Click on your profile picture (at the top right corner), and select `Your repositories`

![ssh key set up](_images/github/your_repos.png 'ssh key set up')

2. At the top, click on `repositories`. The open the repo you created in the previous steps.

![ssh key set up](_images/github/select_repos.png 'ssh key set up')

3. Next, click on `settings`.

![ssh key set up](_images/github/ssh_key_1.png 'ssh key set up')

4. Next, on the left sidebar find `Deploy Keys` and click on it. Then click on `Add Deploy Key`

![ssh key set up](_images/github/ssh_key_2.png 'ssh key set up')

5. In the form that comes up enter `Website Key` or any other name as the title, then click on `Allow write access` to enable it.

![ssh key set up](_images/github/ssh_key_3.png 'ssh key set up')

6. Now go to your google drive and find the folder (directory) called `publishing`. Inside it go to `Website-private` and open `id_rsa.pub.docx`. Copy the contents of the file, then go back to the github page of step 5 and paste inside `key` and submit the form.

7. Go back to colab and press enter

### Getting the Document Id (docId)

The next step is to get a document Id for a google sheet that has been created. To get it, go to your google drive (using the same account you are using to run colab notebook). 

Find the folder (directory) called `publishing`. 

![Publishing Dir](_images/drive/drive_publishing.png 'Publishing Dir') 


Inside it you wil see a folder called `Website`. Right click on it and select `share`.

![Share Website Dir](_images/drive/share_website_dir.png 'Share Website Dir') 

On the pop-up that comes up, under `General Access`, click on `Anyone with link`, then `Done`

![Share Website Dir](_images/drive/anyone_with_link.png 'Share Website Dir') 

Now open the `Website` directory, then `Website Data.xlsx`

Now go to the address bar. You will find a url that is in the format: `https://docs.google.com/spreadsheets/d/1-JcnNlibAopymzBEVyUpaop-M56g9Dy1/edit#gid=1220970150`. Pick the value between `d/` and the next `/` which in this case is `1-JcnNlibAopymzBEVyUpaop-M56g9Dy1`

Go back to colab and enter this value. You will have been prompted for it. Press enter to submit.

### Getting the Sheet Id (sheetId)

Go back to your google sheet and select the `SiteConfig` sheet. 

Open your github repo (using steps provided above, starting by clicking on your profile picture at the top right). In your address bar you will find a url in the format: `https://github.com/gachieforerunner/website`. Copy the equivalent of `gachieforerunner/website`. Put this at the value of `Github` in the `SiteConfig` sheet

Also edit `GitCommitUser` and `GitCommitEmail` with your name and email respectively.

GO back to your google drive and open `Publishing/Website/_posts`. In your address bar, you will find a link in the format: `https://drive.google.com/drive/folders/11Mj8e7OelP7A4JYH32vXN1zKg_1SvUiz`. The folder id is the value after `folders/` which in this case is `11Mj8e7OelP7A4JYH32vXN1zKg_1SvUiz`. Copy it and set it as the value for `postsDirectoryId` in the `SiteConfig` sheet. Set also the values for the other ids for the corresponding folders.

|Key|Value from|
|---|----------|
|postsDirectoryId|`Publishing/Website/_posts`|
|authorDirectoryId|`Publishing/Website/_authors`|
|pagesDirectoryId|`Publishing/Website/_pages`|
|websiteDirId|`Publishing/Website`|
|websitePrivateDirId|`Publishing/Website-private`|

Once you are done with this part of the configuration, cehck the addess bar of your `SiteConfig` sheet. Find the section with `#gid=1537987707`. Copy the value after `#gid=` (the numeric value alone) and enter that into the prompt in colab.

![Site Config](_images/drive/site_config_sheet.png 'Site Config') 

```html
<!-- index.html -->

<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <meta charset="UTF-8" />
    <link
      rel="stylesheet"
      href="//cdn.jsdelivr.net/npm/docsify@4/themes/vue.css"
    />
  </head>
  <body>
    <div id="app"></div>
    <script>
      window.$docsify = {
        //...
      };
    </script>
    <script src="//cdn.jsdelivr.net/npm/docsify@4"></script>
  </body>
</html>
```

## Setting up ssh keys in GitHub

?> Note that in both of the examples below, docsify URLs will need to be manually updated when a new major version of docsify is released (e.g. `v4.x.x` => `v5.x.x`). Check the docsify website periodically to see if a new major version has been released.

Specifying a major version in the URL (`@4`) will allow your site will receive non-breaking enhancements (i.e. "minor" updates) and bug fixes (i.e. "patch" updates) automatically. This is the recommended way to load docsify resources.

```html
<link rel="stylesheet" href="//cdn.jsdelivr.net/npm/docsify@4/themes/vue.css" />
<script src="//cdn.jsdelivr.net/npm/docsify@4"></script>
```

If you prefer to lock docsify to a specific version, specify the full version after the `@` symbol in the URL. This is the safest way to ensure your site will look and behave the same way regardless of any changes made to future versions of docsify.

```html
<link
  rel="stylesheet"
  href="//cdn.jsdelivr.net/npm/docsify@4.11.4/themes/vue.css"
/>
<script src="//cdn.jsdelivr.net/npm/docsify@4.11.4"></script>
```

## Getting the Site Up and Running

If you have Python installed on your system, you can easily use it to run a static server to preview your site.

```python2
cd docs && python -m SimpleHTTPServer 3000
```

```python3
cd docs && python -m http.server 3000
```

## Loading dialog

If you want, you can show a loading dialog before docsify starts to render your documentation:

```html
<!-- index.html -->

<div id="app">Please wait...</div>
```

You should set the `data-app` attribute if you changed `el`:

```html
<!-- index.html -->

<div data-app id="main">Please wait...</div>

<script>
  window.$docsify = {
    el: '#main',
  };
</script>
```

Compare [el configuration](configuration.md#el).
