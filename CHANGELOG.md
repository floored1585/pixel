## 0.0.4 (unreleased)

Bugfixes:

  - Interfaces now record last_updated when they are walked, not when they are processed.
    This should fix a number of inaccuracies in graphs and delta data (bps/pps/etc) (@floored1585)

## 0.0.3 (2016-06-29)

Features:

  - New "Interfaces" page; a framework for searching through interface data (@floored1585)
  - Device page now loads most data via AJAX, for faster initial page load and improved UX (@floored1585)

Bugfixes:

  - Interface.type can no longer return nil (@floored1585)

## 0.0.2 (2016-03-04)

Features:

  - Database schema is now populated automatically for fresh installs (@floored1585)
  - Database schema is now updated automatically as necessary (@floored1585)

## 0.0.1 (2016-03-04)

Initial public release! Woo!
