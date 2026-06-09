"""
The HARNESS — currency-AGNOSTIC simulation engine + the Scenario layer + characterization.

A `Scenario` is the single declarative layer (all forcings). `generate` turns it into dynamics via
ONE rule (Liebig-limited growth over K currencies). Currency topology: closed → excess recycles to
an available pool (conserved); open → dissipates to a terminal sink + an exogenous source.
`classify` labels a run's regime; `sweep2` maps regimes over two Scenario axes.

The intervention ladder lives here: L1 parameters (sweep), L2 structure (toggle species/edges via the
Scenario lists), L3 vocabulary (extend the currency set / primitives). Everything that varies is a
forcing; the engine is invariant.
"""
module Harness

using DifferentialEquations

export Currency, Pool, Feed, Scenario, Layout, generate, run_scenario, classify, sweep2,
       set_pool, set_feed, drifts, ssize, ssize_end

struct Currency; name::Symbol; closed::Bool; end
struct Pool
    name::Symbol; role::Symbol          # :producer | :consumer | :dead
    comp::Vector{Float64}               # body composition (currency per structural unit)
    maint::Float64; mort::Float64; crowd::Float64
    src::Vector{Float64}                # per-currency source (open→exogenous; closed→uptake; 0=none)
    decay::Float64                      # dead pools: strip OPEN currencies → sink (decomposition energy loss)
end
struct Feed; resource::Symbol; consumer::Symbol; rate::Float64; util::Float64; assim::Float64; end
struct Scenario
    currencies::Vector{Currency}; pools::Vector{Pool}; feeds::Vector{Feed}
    detritus::Symbol; init::Dict{Symbol,Vector{Float64}}; avail0::Vector{Float64}
end

struct Layout; K::Int; P::Int; pidx::Dict{Symbol,Int}; closed::Vector{Bool}; comps::Vector{Vector{Float64}}; bav::Int; bsk::Int; bcs::Int; di::Int; end
amt(L,p,k)=(p-1)*L.K+k
function ssize(u,L,p)
    m=Inf
    for k in 1:L.K; c=L.comps[p][k]; c>0 && (m=min(m,u[amt(L,p,k)]/c)); end
    isfinite(m) ? max(m,0.0) : 0.0
end

function generate(scn)
    K=length(scn.currencies); P=length(scn.pools)
    pidx=Dict(p.name=>i for (i,p) in enumerate(scn.pools))
    closed=[c.closed for c in scn.currencies]; comps=[p.comp for p in scn.pools]
    L=Layout(K,P,pidx,closed,comps,P*K,P*K+K,P*K+2K,pidx[scn.detritus])
    fds=[(pidx[f.resource],pidx[f.consumer],f.rate,f.util,f.assim) for f in scn.feeds]
    pools=scn.pools; di=L.di
    function rhs!(du,u,_p,_t)
        fill!(du,0.0)
        for (pi,pl) in enumerate(pools)
            if pl.role==:dead
                if pl.decay>0
                    for k in 1:K; closed[k] && continue
                        x=pl.decay*u[amt(L,pi,k)]; du[amt(L,pi,k)]-=x; du[L.bsk+k]+=x
                    end
                end
                continue
            end
            s=ssize(u,L,pi)
            for k in 1:K
                r=pl.src[k]; r==0 && continue
                if closed[k]; up=r*s*u[L.bav+k]; du[amt(L,pi,k)]+=up; du[L.bav+k]-=up
                else sr=r*s; du[amt(L,pi,k)]+=sr; du[L.bcs+k]+=sr end
            end
            for k in 1:K; closed[k] && continue
                m=pl.maint*u[amt(L,pi,k)]; du[amt(L,pi,k)]-=m; du[L.bsk+k]+=m
            end
            for k in 1:K
                x=(pl.crowd*s+pl.mort)*u[amt(L,pi,k)]; du[amt(L,pi,k)]-=x; du[amt(L,di,k)]+=x
            end
        end
        for (ri,ci,rate,util,a) in fds
            frac=rate*ssize(u,L,ci); assim=zeros(K)
            for k in 1:K
                killed=frac*u[amt(L,ri,k)]; du[amt(L,ri,k)]-=killed
                du[amt(L,di,k)]+=(1-util)*killed
                ing=util*killed; assim[k]=a*ing; du[amt(L,di,k)]+=(1-a)*ing
            end
            g=Inf
            for k in 1:K; c=comps[ci][k]; c>0 && (g=min(g,assim[k]/c)); end
            g=isfinite(g) ? max(g,0.0) : 0.0
            for k in 1:K
                du[amt(L,ci,k)]+=comps[ci][k]*g; ex=assim[k]-comps[ci][k]*g
                closed[k] ? (du[L.bav+k]+=ex) : (du[L.bsk+k]+=ex)
            end
        end
    end
    u0=zeros(P*K+3K)
    for (nm,v) in scn.init, k in 1:K; u0[amt(L,pidx[nm],k)]=v[k]; end
    for k in 1:K; u0[L.bav+k]=scn.avail0[k]; end
    rhs!, u0, L
end

function run_scenario(scn; T=600.0)
    rhs!,u0,L=generate(scn)
    solve(ODEProblem(rhs!,u0,(0.0,T)),Tsit5();saveat=T/200,abstol=1e-9,reltol=1e-9), L
end

function drifts(sol,L)
    cd=Float64[]; od=Float64[]
    for k in 1:L.K
        tot(u)=sum(u[amt(L,p,k)] for p in 1:L.P)
        if L.closed[k]
            f(u)=tot(u)+u[L.bav+k]; push!(cd, maximum(abs(f(u)-f(sol.u[1])) for u in sol.u)/max(f(sol.u[1]),1e-9))
        else
            g(u)=tot(u)+u[L.bsk+k]-u[L.bcs+k]; push!(od, maximum(abs(g(u)-g(sol.u[1])) for u in sol.u)/(sol.u[end][L.bcs+k]+tot(sol.u[1])+1e-9))
        end
    end
    cd, od
end
ssize_end(sol,L,nm)=ssize(sol.u[end],L,L.pidx[nm])

function classify(sol,L,living)
    cd,od=drifts(sol,L); conserved=all(<(1e-6),cd)&&all(<(1e-6),od)
    tail=sol.u[max(1,end-div(length(sol.u),4)):end]; surviving=Symbol[]; osc=false
    for nm in living
        p=L.pidx[nm]; sz=[ssize(u,L,p) for u in tail]; mean=sum(sz)/length(sz)
        if mean>1e-3
            push!(surviving,nm); (maximum(sz)-minimum(sz))/max(mean,1e-9)>0.05 && (osc=true)
        end
    end
    regime=isempty(surviving) ? :collapse : (osc ? :cycle : :fixed)
    (; surviving, regime, conserved)
end

function set_pool(scn,name,field,v)
    pools=map(scn.pools) do p
        p.name==name ? Pool(p.name,p.role,p.comp, field===:maint ? v : p.maint, field===:mort ? v : p.mort,
                            field===:crowd ? v : p.crowd, p.src, field===:decay ? v : p.decay) : p
    end
    Scenario(scn.currencies,pools,scn.feeds,scn.detritus,scn.init,scn.avail0)
end
function set_feed(scn,res,cons,field,v)
    feeds=map(scn.feeds) do f
        (f.resource==res&&f.consumer==cons) ? Feed(f.resource,f.consumer, field===:rate ? v : f.rate,
                            field===:util ? v : f.util, field===:assim ? v : f.assim) : f
    end
    Scenario(scn.currencies,scn.pools,feeds,scn.detritus,scn.init,scn.avail0)
end

function sweep2(base,ax1,ax2;living,T=600.0)
    M=Matrix{Any}(undef,length(ax1[2]),length(ax2[2]))
    for (i,v1) in enumerate(ax1[2]), (j,v2) in enumerate(ax2[2])
        scn=ax2[3](ax1[3](base,v1),v2); sol,L=run_scenario(scn;T); M[i,j]=classify(sol,L,living)
    end
    M
end

end # module Harness
