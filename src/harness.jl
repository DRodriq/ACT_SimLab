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
       set_pool, set_feed, drifts, ssize, ssize_end,
       grid_edges, generate_spatial, run_spatial, drifts_spatial, role_field   # spatial layer

struct Currency; name::Symbol; closed::Bool; end
struct Pool
    name::Symbol; role::Symbol          # :producer | :consumer | :dead
    comp::Vector{Float64}               # body composition (currency per structural unit)
    maint::Float64; mort::Float64; crowd::Float64
    src::Vector{Float64}                # per-currency source (open→exogenous; closed→uptake; 0=none)
    decay::Float64                      # dead pools: OPEN currencies → sink (energy respired to heat)
    mineralize::Float64                 # dead pools: CLOSED currencies → available pool (nutrient released)
end
Pool(n,r,comp,ma,mo,cr,s,d) = Pool(n,r,comp,ma,mo,cr,s,d,0.0)   # back-compat (8-arg, no mineralization)
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
            if pl.role==:dead                       # detritus subsystem: per-currency outflow
                for k in 1:K
                    if closed[k]                        # nutrient → mineral (slow): the fertilizer outflow
                        pl.mineralize>0 || continue
                        x=pl.mineralize*u[amt(L,pi,k)]; du[amt(L,pi,k)]-=x; du[L.bav+k]+=x
                    else                                # energy → heat (fast): respiration
                        pl.decay>0 || continue
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

# ===== Spatial layer: distribute a Scenario over an N×N grid + diffuse mobile pools =====
# State: A[tile,pool,currency] (T·P·K), AV[tile,currency] (local available pools), SK/CS (global).
# Local rules run per tile; mobile pools diffuse (graph Laplacian) between 4-neighbours. Conserves
# each currency globally (closed: Σpools+Σavail invariant; open: Σpools+sink−source invariant).

function grid_edges(N)
    e=Tuple{Int,Int}[]; idx(r,c)=(r-1)*N+c
    for r in 1:N, c in 1:N
        c<N && push!(e,(idx(r,c),idx(r,c+1)))
        r<N && push!(e,(idx(r,c),idx(r+1,c)))
    end
    e
end

function generate_spatial(scn, N, mobile)
    K=length(scn.currencies); P=length(scn.pools); T=N*N
    pidx=Dict(p.name=>i for (i,p) in enumerate(scn.pools))
    closed=[c.closed for c in scn.currencies]; comps=[p.comp for p in scn.pools]
    di=pidx[scn.detritus]; pools=scn.pools
    feeds=[(pidx[f.resource],pidx[f.consumer],f.rate,f.util,f.assim) for f in scn.feeds]
    edges=grid_edges(N); mob=[(pidx[nm],r) for (nm,r) in mobile]
    bAV=T*P*K; bSK=bAV+T*K; bCS=bSK+K
    Ai(t,p,k)=((t-1)*P+(p-1))*K+k
    AVi(t,k)=bAV+(t-1)*K+k
    function ssz(u,t,p)
        m=Inf; for k in 1:K; c=comps[p][k]; c>0 && (m=min(m,u[Ai(t,p,k)]/c)); end
        isfinite(m) ? max(m,0.0) : 0.0
    end
    function rhs!(du,u,_p,_t)
        fill!(du,0.0)
        for t in 1:T
            for (pi,pl) in enumerate(pools)
                if pl.role==:dead
                    for k in 1:K
                        if closed[k]
                            pl.mineralize>0 || continue
                            x=pl.mineralize*u[Ai(t,pi,k)]; du[Ai(t,pi,k)]-=x; du[AVi(t,k)]+=x
                        else
                            pl.decay>0 || continue
                            x=pl.decay*u[Ai(t,pi,k)]; du[Ai(t,pi,k)]-=x; du[bSK+k]+=x
                        end
                    end
                    continue
                end
                s=ssz(u,t,pi)
                for k in 1:K
                    r=pl.src[k]; r==0 && continue
                    if closed[k]; up=r*s*u[AVi(t,k)]; du[Ai(t,pi,k)]+=up; du[AVi(t,k)]-=up
                    else sr=r*s; du[Ai(t,pi,k)]+=sr; du[bCS+k]+=sr end
                end
                for k in 1:K; closed[k] && continue
                    m=pl.maint*u[Ai(t,pi,k)]; du[Ai(t,pi,k)]-=m; du[bSK+k]+=m
                end
                for k in 1:K
                    x=(pl.crowd*s+pl.mort)*u[Ai(t,pi,k)]; du[Ai(t,pi,k)]-=x; du[Ai(t,di,k)]+=x
                end
            end
            for (ri,ci,rate,util,a) in feeds
                frac=rate*ssz(u,t,ci); assim=zeros(K)
                for k in 1:K
                    killed=frac*u[Ai(t,ri,k)]; du[Ai(t,ri,k)]-=killed
                    du[Ai(t,di,k)]+=(1-util)*killed
                    ing=util*killed; assim[k]=a*ing; du[Ai(t,di,k)]+=(1-a)*ing
                end
                g=Inf; for k in 1:K; c=comps[ci][k]; c>0 && (g=min(g,assim[k]/c)); end
                g=isfinite(g) ? max(g,0.0) : 0.0
                for k in 1:K
                    du[Ai(t,ci,k)]+=comps[ci][k]*g; ex=assim[k]-comps[ci][k]*g
                    closed[k] ? (du[AVi(t,k)]+=ex) : (du[bSK+k]+=ex)
                end
            end
        end
        for (t1,t2) in edges, (pm,dr) in mob, k in 1:K   # diffusion of mobile pools
            flux=dr*(u[Ai(t1,pm,k)]-u[Ai(t2,pm,k)])
            du[Ai(t1,pm,k)]-=flux; du[Ai(t2,pm,k)]+=flux
        end
    end
    u0=zeros(bCS+K)
    for t in 1:T
        for (nm,v) in scn.init, k in 1:K; u0[Ai(t,pidx[nm],k)]=v[k]; end
        for k in 1:K; u0[AVi(t,k)]=scn.avail0[k]; end
    end
    L=(K=K,P=P,T=T,N=N,pidx=pidx,closed=closed,Ai=Ai,AVi=AVi,bSK=bSK,bCS=bCS,ssz=ssz)
    rhs!,u0,L
end

function run_spatial(scn,N,mobile;T=300.0,seed=nothing)
    rhs!,u0,L=generate_spatial(scn,N,mobile)
    seed===nothing || seed(u0,L)
    solve(ODEProblem(rhs!,u0,(0.0,T)),Tsit5();saveat=T/100,abstol=1e-8,reltol=1e-8), L
end

function drifts_spatial(sol,L)
    cd=Float64[]; od=Float64[]
    for k in 1:L.K
        psum(u)=sum(u[L.Ai(t,p,k)] for t in 1:L.T, p in 1:L.P)
        if L.closed[k]
            tot(u)=psum(u)+sum(u[L.AVi(t,k)] for t in 1:L.T)
            push!(cd, maximum(abs(tot(u)-tot(sol.u[1])) for u in sol.u)/max(tot(sol.u[1]),1e-9))
        else
            f(u)=psum(u)+u[L.bSK+k]-u[L.bCS+k]
            push!(od, maximum(abs(f(u)-f(sol.u[1])) for u in sol.u)/(sol.u[end][L.bCS+k]+psum(sol.u[1])+1e-9))
        end
    end
    cd,od
end

role_field(u,L,role) = (p=L.pidx[role]; [L.ssz(u,(r-1)*L.N+c,p) for r in 1:L.N, c in 1:L.N])

end # module Harness
