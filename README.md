# Listen Along

Listen along to music with your friends through Spotify.

[Listen Along](http://listenalong.club/)

# Install

```bash
bundle
rails db:create && db:migrate
```

# Test

To test without generating a coverage report:

```bash
bundle exec rspec
```

To test and generate a coverage report (a bit slower):

```bash
DISABLE_SPRING=true COVERAGE=true bundle exec rspec
```

The coverage report may be opened with:

```bash
open coverage/index.html
```

To validate that no known vulnerabilities exist in any dependencies:

```bash
bundle audit
```

To test, generate a coverage report, and validate that no known vulnerabilities exist in any dependencies (do this before committing to master):

```bash
bundle audit && DISABLE_SPRING=true COVERAGE=true bundle exec rspec
```

# Run

```bash
bundle exec rails s
```

