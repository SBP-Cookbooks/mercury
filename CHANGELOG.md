# CHANGE LOG for Mercury

 This file is used to list changes made in each major version of Mercury.

## 1.2.5
Changes:
  * Now defaults to Mercury version 0.12.3

## 1.2.3
Changes:
  * Now defaults to Mercury version 0.12.1

## 1.2.2
Changes:
  * Now defaults to Mercury version 0.12.0

## 1.2.1
Changes:
  * Now defaults to Mercury version 0.11.1

## 1.2.0
Changes:
  * Now supports Mercury version 0.10.0 and up

### Important:
With support of multiple healthchecks the healthcheck attribute has been renamed to healthchecks and this is now an array.
In terms of chef attributes that means that you can convert: healthcheck: {} to healthchecks: [{}].
This has been made backwards compatible so that using the old healthcheck will keep working, but do NOT combine both healthcheck and healthchecks as only 1 will work.

## 1.1.0:
Changes:
  * Now supports Mercury version 0.9.0 and up
  * Adjust default log level to info

## 1.0.0:
  * Start of change log
