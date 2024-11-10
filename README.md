# aws_static_website_cdn

## Setup

Check aws configration

```
cat ~/.aws/*
```

## Deploy

```
terraform init
terraform plan
terraform apply
```

### Test

```
http://<bucket name>.s3-website.us-east-1.amazonaws.com/
```

## Destroy

```
terraform destroy
```