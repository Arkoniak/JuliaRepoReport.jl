using HTTP
using JSON3
using Dates
using CSV
using Mustache
using Underscores
using DataFrames
using Logging, LoggingFacilities

@_ ConsoleLogger(stdout; show_limited=false) |> 
   OneLineTransformerLogger |> 
   TimestampTransformerLogger(__, BeginningMessageLocation(); format = "yyyy-mm-dd HH:MM:SS") |>
   global_logger

const TOKEN = strip(read("pat", String))
const GRAPHQLURL = "https://api.github.com/graphql"
const OUTFILE = "jlgh.csv"
const DATAROOT = "data"
const REPOS = [
               # ("JuliaLang", "julia", "jlgh.csv"),
               # ("rust-lang", "rust", "rustgh.csv"),
               ("chapel-lang", "chapel", "chapelgh.csv"),
               ("nim-lang", "Nim", "nim.csv"),
]
const QUERY = mt"""
query {
    repository(owner:"{{ owner }}", name:"{{ repo }}") {
      pullRequests(first:100{{{ cursor }}}) {
      edges {
        cursor
        node {
          author {
            login
          }
          baseRefName
          closed
          closedAt
          createdAt
          locked
          mergeable
          merged
          mergedAt
          mergedBy {
            login
          }
          number
          state
          title
        }
      }
    }
  }
}
"""

const REMAIN_QUERY = """
query {
  viewer {
    login
  }
  rateLimit {
    limit
    cost
    remaining
    resetAt
  }
}
"""

struct PR
    number::Int
    state::String
    author::String
    createdAt::DateTime
    merged::Bool
    mergedAt::DateTime
    mergedBy::String
    closed::Bool
    closedAt::DateTime
    # title::String
end

function PR(node)
    number = node.number
    state = node.state
    author = isnothing(node.author) ? "" : node.author.login
    createdAt = DateTime(node.createdAt[1:end-1])
    merged = node.merged
    mergedAt = isnothing(node.mergedAt) ? DateTime(0) : DateTime(node.mergedAt[1:end-1])
    mergedBy = isnothing(node.mergedBy) ? "" : node.mergedBy.login
    closed = node.closed
    closedAt = isnothing(node.closedAt) ? DateTime(0) : DateTime(node.closedAt[1:end-1])
    # title = node.title

    # PR(number, state, author, createdAt, merged, mergedAt, mergedBy, closed, closedAt, title)
    PR(number, state, author, createdAt, merged, mergedAt, mergedBy, closed, closedAt)
end

function execute(query, graphqlurl = GRAPHQLURL, token = TOKEN)
    body = JSON3.write(Dict("query" => query))
    res = HTTP.request("POST", "https://api.github.com/graphql", Dict("Authorization" => "bearer $token"), body)

    return JSON3.read(String(res.body))
end

function remain(; query = REMAIN_QUERY)
    res = execute(query)
    res = res.data.rateLimit
    return (; limit = res.limit, reset_ts = DateTime(res.resetAt[1:end-1]), remaining = res.remaining)
end

function collect(owner, repo, output = OUTFILE; query = QUERY)
    q = render(query, Dict("cursor" => "", "owner" => owner, "repo" => repo))
    res = execute(q)
    cursor = res.data.repository.pullRequests.edges[end].cursor
    res = @_ map(PR(_.node), res.data.repository.pullRequests.edges)
    num = res[end].number
    @info "Current PR number: " num
    res = DataFrame(res)
    CSV.write(output, res; delim = '\1', append = false)
    r = remain()
    @info "Remain: " r.limit r.remaining r.reset_ts
    while true
        q = render(query, Dict("cursor" => ", after: \"$cursor\"", "owner" => owner, "repo" => repo))
        res = execute(q)
        isempty(res.data.repository.pullRequests.edges) && break
        cursor = res.data.repository.pullRequests.edges[end].cursor
        res = @_ map(PR(_.node), res.data.repository.pullRequests.edges)
        num = res[end].number
        @info "Current PR number: " num
        res = DataFrame(res)
        CSV.write(output, res; delim = '\1', append = true)
        r = remain()
        @info "Remain: " r.limit r.remaining r.reset_ts
    end
end

for (owner, repo, outfile) in REPOS
    outfile = joinpath(DATAROOT, outfile)
    collect(owner, repo, outfile)
end
