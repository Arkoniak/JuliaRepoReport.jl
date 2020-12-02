# Julia repository exploration

## Collect data

Data collector is located in `collector.jl` file and should be run with
```julia
julia --project=. collector.jl
```
Before running this script though, you should [create token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) and store it in file `pat`. Alternatively you can fix `collector.jl` and get token from `ENV` or read it any other way.

As a result it creates file `data/jlgh.csv` (name can be changed by adjusting `OUTFILE` parameter in `collector.jl`), which contains following data about repository

1. `number`: PR number
2. `state`: PR state: OPEN, CLOSED, MERGED. If PR was MERGED, then it was also closed (look below)
3. `author`: nickname of the PR author. Can be empty (presumably, if account was deleted from github or due to some errors in github).
4. `createdAt`: timestamp when PR was created
5. `merged`: boolean, whether PR was merged or not
6. `mergedAt`: timestamp when PR was merged. If it was not merged, this timestamp equals to `DateTime(0)`
7. `mergedBy`: nickname of the user, who has merged this PR. Empty if PR was not merged.
8. `closed`: boolean, whether PR was closed or not. Equals `false` if PR is still open, `true` otherwise.
9. `closedAt`: timestamp when PR was closed. If it was not closed, this timestamp equals to `DateTime(0)`. If PR was merged, usually this timestamp differ by 1 second from `mergedAt`


## Data visualization

You can read the report in `plutovis.jl`, which is a `Pluto.jl` file and should be read accordingly, or you can see `plutovis.html` which is the rendered version of the `plutovis.jl`


## Reports

Here is list of reports:

* Julia: https://arkoniak.github.io/JuliaRepoReport.jl/plutovis.html
* Rust: https://arkoniak.github.io/JuliaRepoReport.jl/rustvis.html
* Chapel: https://arkoniak.github.io/JuliaRepoReport.jl/chapelvis.html
* Nim: https://arkoniak.github.io/JuliaRepoReport.jl/nimvis.html
