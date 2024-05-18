@doc raw"""
	spatialgraph(S)
	spatialgraph(S, Z)
	spatialgraph(g::GNNGraph, Z)
Given data `Z` and spatial locations `S`, constructs a
[`GNNGraph`](https://carlolucibello.github.io/GraphNeuralNetworks.jl/stable/api/gnngraph/#GNNGraph-type)
ready for use in a graph neural network that employs [`SpatialGraphConv`](@ref) or [`GraphConv`](https://carlolucibello.github.io/GraphNeuralNetworks.jl/dev/api/conv/#GraphNeuralNetworks.GraphConv) layers.

Let $\mathcal{D} \subset \mathbb{R}^d$ denote the spatial domain of interest.
When $m$ independent replicates are collected over the same set of
$n$ spatial locations,
```math
\{\boldsymbol{s}_1, \dots, \boldsymbol{s}_n\} \subset \mathcal{D},
```
`Z` should be given as an $n \times m$ matrix and `S` should be given as a $n \times d$ matrix. 
Otherwise, when $m$ independent replicates
are collected over differing sets of spatial locations,
```math
\{\boldsymbol{s}_{ij}, \dots, \boldsymbol{s}_{in_i}\} \subset \mathcal{D}, \quad i = 1, \dots, m,
```
`Z` should be given as an $m$-vector of $n_i$-vectors,
and `S` should be given as an $m$-vector of $n_i \times d$ matrices.

The spatial information between neighbours is stored as an edge feature, with the specific 
information controlled by the keyword arguments `stationary` and `isotropic`. 
Specifically, the edge feature between node  $j$ and node $j'$ stores the spatial 
distance $\|\boldsymbol{s}_{j'} - \boldsymbol{s}_j\|$ (if `isotropic`), the spatial 
displacement $\boldsymbol{s}_{j'} - \boldsymbol{s}_j$ (if `stationary`), or the matrix of  
locations $(\boldsymbol{s}_{j'}, \boldsymbol{s}_j)$ (if `!stationary`).  

Additional keyword arguments inherit from the arguments [`adjacencymatrix()`](@ref) to determined the 
structure of the neighbourhoods of each node, with the default being a randomly selected set of 
`k=30` neighbours within a disc of radius `r=0.15`.

# Examples
```
using NeuralEstimators

# Number of replicates and spatial dimension
m = 5  
d = 2  

# Spatial locations fixed for all replicates
n = 100
S = rand(n, d)
Z = rand(n, m)
g = spatialgraph(S, Z)

# Spatial locations varying between replicates
n = rand(50:100, m)
S = rand.(n, d)
Z = rand.(n)
g = spatialgraph(S, Z)
```
"""
function spatialgraph(S::AbstractMatrix; stationary = true, isotropic = true, store_S::Bool = false, pyramid_pool::Bool = false, kwargs...)

	# Determine neighbourhood based on keyword arguments 
	#TODO change default to whatever I decide in the paper
	kwargs = (;kwargs...)
	k = haskey(kwargs, :k) ? kwargs.k : 30
	r = haskey(kwargs, :r) ? kwargs.r : 0.15

	if !isotropic #TODO (need to modify adjacencymatrix() to do this)
		error("Anistropy is not currently implemented (although it is documented in anticipation of future functionality); please contact the package maintainer")
	end
	if !stationary #TODO (need to modify adjacencymatrix() to do this)
		error("Nonstationarity is not currently implemented (although it is documented anticipation of future functionality); please contact the package maintainer")
	end
	ndata = DataStore()
	S = Float32.(S)
	A = adjacencymatrix(S; k = k, r = r) #TODO figure out what I'm doing with kwargs
	S = permutedims(S) # need final dimension to be n-dimensional
	if store_S
		ndata = (ndata..., S = S)
	end
	if pyramid_pool # NB not documenting pyramid_pool for now because it is experimental
		clusterings = computeclusters(S)
		ndata = (ndata..., clusterings = clusterings)
	end
	GNNGraph(A, ndata = ndata, edata = permutedims(A.nzval))
end
spatialgraph(S::AbstractVector; kwargs...) = batch(spatialgraph.(S; kwargs...)) # spatial locations varying between replicates

# Wrappers that allow data to be passed into an already-constructed graph
# (useful for partial simulation on the fly with the parameters held fixed)
spatialgraph(g::GNNGraph, Z) = GNNGraph(g, ndata = (g.ndata..., Z = reshapeZ(Z)))
reshapeZ(Z::V) where V <: AbstractVector{A} where A <: AbstractArray = stackarrays(reshapeZ.(Z))
reshapeZ(Z::AbstractVector) = reshapeZ(reshape(Z, length(Z), 1))
reshapeZ(Z::AbstractMatrix) = reshapeZ(reshape(Z, 1, size(Z)...))
function reshapeZ(Z::A) where A <: AbstractArray{T, 3} where {T}
	# Z is given as a three-dimensional array, with
	# Dimension 1: q, dimension of the response variable (e.g., singleton with univariate data)
	# Dimension 2: n, number of spatial locations
	# Dimension 3: m, number of replicates
	# Permute dimensions 2 and 3 since GNNGraph requires final dimension to be n-dimensional
	permutedims(Float32.(Z), (1, 3, 2))
end
function reshapeZ(Z::V) where V <: AbstractVector{M} where M <: AbstractMatrix{T} where T 
	# method for multidimensional processes with spatial locations varying between replicates
	z = reduce(hcat, Z)
	reshape(z, size(z, 1), 1, size(z, 2))
end 

# Wrapper that allows Z to be included at construction time
function spatialgraph(S, Z; kwargs...) 
	g = spatialgraph(S; kwargs...)
	spatialgraph(g, Z)
end

# NB Not documenting for now, but spatialgraph is set up for multivariate data. Eventually, we will write:
# "Let $q$ denote the dimension of the spatial process (e.g., $q = 1$ for 
# univariate spatial processes, $q = 2$ for bivariate processes, etc.)". For fixed locations, we will then write: 
# "`Z` should be given as a $q \times n \times m$ array (alternatively as an $n \times m$ matrix when $q = 1$) and `S` should be given as a $n \times d$ matrix."
# And for varying locations, we will write: 
# "`Z` should be given as an $m$-vector of $q \times n_i$ matrices (alternatively as an $m$-vector of $n_i$-vectors when $q = 1$), and `S` should be given as an $m$-vector of $n_i \times d$ matrices."
# Then update examples to show q > 1:
# # Examples
# ```
# using NeuralEstimators
#
# # Number of replicates, and spatial dimension
# m = 5  
# d = 2  
#
# # Spatial locations fixed for all replicates
# n = 100
# S = rand(n, d)
# Z = rand(n, m)
# g = spatialgraph(S)
# g = spatialgraph(g, Z)
# g = spatialgraph(S, Z)
#
# # Spatial locations varying between replicates
# n = rand(50:100, m)
# S = rand.(n, d)
# Z = rand.(n)
# g = spatialgraph(S)
# g = spatialgraph(g, Z)
# g = spatialgraph(S, Z)
#
# # Mutlivariate processes: spatial locations fixed for all replicates
# q = 2 # bivariate spatial process
# n = 100
# S = rand(n, d)
# Z = rand(q, n, m)  
# g = spatialgraph(S)
# g = spatialgraph(g, Z)
# g = spatialgraph(S, Z)
#
# # Mutlivariate processes: spatial locations varying between replicates
# n = rand(50:100, m)
# S = rand.(n, d)
# Z = rand.(q, n)
# g = spatialgraph(S)
# g = spatialgraph(g, Z) 
# g = spatialgraph(S, Z) 
# ```

# ---- GraphConv ----

# 3D array version of GraphConv to allow the option to forego spatial information

"""
	(l::GraphConv)(g::GNNGraph, x::A) where A <: AbstractArray{T, 3} where {T}

Given a graph with node features a three dimensional array of size `in` × m × n, 
where n is the number of nodes in the graph, this method yields an array with 
dimensions `out` × m × n. 

# Examples
```
using NeuralEstimators, Flux, GraphNeuralNetworks

q = 2                       # dimension of response variable
n = 100                     # number of nodes in the graph
e = 200                     # number of edges in the graph
m = 30                      # number of replicates of the graph
g = rand_graph(n, e)        # fixed structure for all graphs
Z = rand(d, m, n)           # node data varies between graphs
g = GNNGraph(g; ndata = Z)

# Construct and apply graph convolution layer
l = GraphConv(d => 16)
l(g)
```
"""
function (l::GraphConv)(g::GNNGraph, x::A) where A <: AbstractArray{T, 3} where {T}
    check_num_nodes(g, x)
    m = GraphNeuralNetworks.propagate(copy_xj, g, l.aggr, xj = x)
    l.σ.(l.weight1 ⊠ x .+ l.weight2 ⊠ m .+ l.bias) # ⊠ is shorthand for batched_mul
end


# ---- SpatialGraphConv ----

# import Flux: Bilinear
# # function (b::Bilinear)(Z::A) where A <: AbstractArray{T, 3} where T
# # 	@assert size(Z, 2) == 2
# # 	x = Z[:, 1, :]
# # 	y = Z[:, 2, :]
# # 	b(x, y)
# # end

# With a skip connection
# GNN = GNNChain(
# 	GraphSkipConnection(SpatialGraphConv(1 => 16)),
# 	SpatialGraphConv(16 + 1 => 32) # one extra input dimension corresponding to the input data
# )
# GNN(g)

#TODO
# stationary but anisotropic
# g = spatialgraph(S, Z; isotropic = false)
# layer = SpatialGraphConv(1 => 16; isotropic = false)
# layer(g)
#
# nonstationary
# g = spatialgraph(S, Z; stationary = false)
# layer = SpatialGraphConv(1 => 16; stationary = false)
# layer(g)


#TODO update documentation
@doc raw"""
    SpatialGraphConv(in => out, g=relu; aggr=mean, bias=true, init=glorot_uniform, w_arguments...)

Implements spatial graph convolution ([Danel et al., 2020)](https://arxiv.org/abs/1909.05310)),
```math
 \boldsymbol{h}^{(l)}_{j} =
 g\Big(
 \boldsymbol{\Gamma}_{\!1}^{(l)} \boldsymbol{h}^{(l-1)}_{j}
 +
 \boldsymbol{\Gamma}_{\!2}^{(l)} \bar{\boldsymbol{h}}^{(l)}_{j}
 +
 \boldsymbol{\gamma}^{(l)}
 \Big),
 \quad
 \bar{\boldsymbol{h}}^{(l)}_{j} = \sum_{j' \in \mathcal{N}(j)}\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}; \boldsymbol{\beta}^{(l)}) \odot \boldsymbol{h}^{(l-1)}_{j'},
```
where $\boldsymbol{h}^{(l)}_{j}$ is the hidden feature vector at location
$\boldsymbol{s}_j$ at layer $l$, $g(\cdot)$ is a non-linear activation function
applied elementwise, $\boldsymbol{\Gamma}_{\!1}^{(l)}$ and
$\boldsymbol{\Gamma}_{\!2}^{(l)}$ are trainable parameter matrices,
$\boldsymbol{\gamma}^{(l)}$ is a trainable bias vector, $\mathcal{N}(j)$ denotes the
indices of neighbours of $\boldsymbol{s}_j$, $\boldsymbol{w}(\cdot, \cdot; \boldsymbol{\beta}^{(l)})$ is a
learnable weight function parameterised by $\boldsymbol{\beta}^{(l)}$, and $\odot$
denotes elementwise multiplication. Note that summation 
may be replaced by another aggregation function, such as the elementwise mean or
maximum.

The spatial information should be stored as edge features. In the general case, 
the edge feature between node $j$ and node $j'$ should contain the matrix of locations 
locations $(\boldsymbol{s}_{j'}, \boldsymbol{s}_j)$. When modelling stationary processes,  
$\boldsymbol{w}(\cdot, \cdot)$ can be made a function of spatial displacement, so that
$\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}) \equiv \boldsymbol{w}(\boldsymbol{s}_{j'} - \boldsymbol{s}_j)$, 
in which case the edge feature between node $j$ and node $j'$ should contain 
$\boldsymbol{s}_{j'} - \boldsymbol{s}_j$. When modelling isotropic processes, $\boldsymbol{w}(\cdot, \cdot)$ 
can be made a function of spatial distance, so that
$\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}) \equiv \boldsymbol{w}(\|\boldsymbol{s}_{j'} - \boldsymbol{s}_j\|)$, 
in which case the edge feature between node 
$j$ and node $j'$ should contain $\|\boldsymbol{s}_{j'} - \boldsymbol{s}_j\|$. 
Note that this preprocessing is facilitated by [`spatialgraph()`](@ref). 

The model for $\boldsymbol{w}(\cdot, \cdot)$ is a multilayer perceptron with a single hidden layer. 

The output of $\boldsymbol{w}(\cdot, \cdot)$ may be chosen to be scalar or a vector 
of the same dimension as the feature vectors of the previous layer. At the first 
layer, the "feature" vector corresponds to the spatial datum and, for univariate spatial processes, the
dimension of $\boldsymbol{w}(\cdot, \cdot)$ will be equal to
one, which may be a source of inflexibility. To increase flexibility, one may
construct several "channels" by constructing the intermediate representation as

```math
\bar{\boldsymbol{h}}^{(l)}_{j} =
\sum_{j' \in \mathcal{N}(j)}
\Big(
\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}; \boldsymbol{\beta}_{1}^{(l)})
\oplus
\dots
\oplus
\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}; \boldsymbol{\beta}_{c}^{(l)})
\Big)
\odot
\Big(
 \boldsymbol{h}^{(l-1)}_{j'}
\oplus
\dots
\oplus
 \boldsymbol{h}^{(l-1)}_{j'}
\Big),
```
where $c$ denotes the number of channels and $\oplus$ denotes vector concatentation.

Note that one may use a [`GraphConv`](https://carlolucibello.github.io/GraphNeuralNetworks.jl/dev/api/conv/#GraphNeuralNetworks.GraphConv) layer that foregoes the use of spatial information entirely. 

# Arguments
- `in`: The dimension of input features.
- `out`: The dimension of output features.
- `g = relu`: Activation function.
- `aggr = mean`: Aggregation operator (e.g. `+`, `*`, `max`, `min`, and `mean`).
- `bias = true`: Add learnable bias?
- `init = glorot_uniform`: Initialiser for $\boldsymbol{\Gamma}_{\!1}^{(l)}$, $\boldsymbol{\Gamma}_{\!2}^{(l)}$, and $\boldsymbol{\gamma}^{(l)}$.
- `d = 2`: Dimension of spatial locations.
- `stationary = true`:  If `true`, $\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}) \equiv \boldsymbol{w}(\boldsymbol{s}_{j'} - \boldsymbol{s}_j)$.
- `isotropic = true`:  If `true` and `stationary` is also `true`, $\boldsymbol{w}(\boldsymbol{s}_j, \boldsymbol{s}_{j'}) \equiv \boldsymbol{w}(\|\boldsymbol{s}_{j'} - \boldsymbol{s}_j\|)$.
- `w_scalar = false`: If `true`, $\boldsymbol{w}(\cdot, \cdot)$ is defined to be a scalar function, that is, $\boldsymbol{w}(\cdot, \cdot) \equiv  w(\cdot, \cdot)$.
- `w_width`: Width of the hidden layer of $\boldsymbol{w}(\cdot, \cdot)$ (when modelled as an MLP).
- `w_g`: Activation function used in $\boldsymbol{w}(\cdot, \cdot)$ (when modelled as an MLP).
- `w_channels = 1`: The number of "channels" of $\boldsymbol{w}(\cdot, \cdot)$.
- `w_init`: Initialiser for the parameters of $\boldsymbol{w}(\cdot, \cdot)$.

# Examples
```
using NeuralEstimators, Flux, GraphNeuralNetworks
using Statistics: mean

# Toy spatial data
m = 5                  # number of replicates
d = 2                  # spatial dimension
n = 250                # number of spatial locations
S = rand(n, d)         # spatial locations
Z = rand(n, m)         # data
g = spatialgraph(S, Z) # construct the graph
G = Flux.batch([g, g]) # super graph 

# Construct and apply spatial graph convolution layers
#layer1 = SpatialGraphConv(1 => 16)
#layer2 = SpatialGraphConv(16 => 32)
#g |> layer1 |> layer2


function SGC(ch::Pair{Int,Int}, glob)
	in, out = ch
	wi = 32
	w = Chain(
		Dense(1 => wi, relu),
		Dense(wi => wi, relu),
		Dense(wi => out, relu)
	)
	ψ = Chain(
		Dense(1 => wi, relu),
		Dense(wi => wi, relu),
		Dense(wi => out, relu)
	)
	ρ = Chain(
		Dense(2*out => wi, relu),
		Dense(wi => wi, relu),
		Dense(wi => out, relu)
	)
	SpatialGraphConv(w, ψ, ρ, glob)
end 


l1 = SGC(1 => 10, true)
l1 = SGC(1 => 10, false)
l2 = SGC(1 => 10, false) 

l2(l1(g))

propagation = GNNChain(
	SGC(1 => 10, false),
	SGC(1 => 10, false) 
	)
readout = GlobalPool(mean)
ψ = GNNSummary(propagation, readout)
R = ψ(g)
R = ψ(G)

globalfeatures = SGC(1 => 10, true)
globalfeatures(g)
globalfeatures(G)

ψ = GNNSummary(propagation, readout, globalfeatures)
ψ(g)
ψ(G)

ϕ = Chain(Dense(20, 32, relu), Dense(32, 3))
θ̂ = DeepSet(ψ, ϕ)
θ̂(g) 
θ̂(G)

θ̂([g, g]) 
θ̂([G, G]) 
```
"""
struct SpatialGraphConv{A, B, C} <: GNNLayer
    w::C
	ψ::A
	ρ::B
    #f::D #TODO
    glob::Bool 
end
@layer SpatialGraphConv
WeightedGraphConv = SpatialGraphConv; export WeightedGraphConv # alias for backwards compatability
function SpatialGraphConv(
	ch::Pair{Int,Int},
	g = relu;
	aggr = mean,
	init = glorot_uniform,
	bias::Bool = true,
	d::Integer = 2,
	isotropic::Bool = true,
	stationary::Bool = true,
	w_channels::Integer = 1,
	w_init = glorot_uniform, #TODO maybe use rand32 by default (play with this and see what would be best)
	w_scalar = false, 
	w_width::Integer = 16,
	w_g = relu, 
	glob::Bool = false # TODO
	)

	#TODO need to update this constructor

	# Weight matrix
	in, out = ch
    Γ1 = init(out, in)
    Γ2 = init(out, in * w_channels)

	# Bias vector
	b = bias ? Flux.create_bias(Γ1, true, out) : false

	# Spatial locations summary network 
	ψ = if isotropic
		Chain(
			Dense(1 => w_width, w_g, init = w_init),
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	elseif stationary 
		Chain(
			Dense(d => w_width, w_g, init = w_init),
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	else
		Chain(
			Bilinear((d, d) => w_width, w_g, init = w_init),  
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	end 

	# Spatial weighting function
	w_dim = w_scalar ? 1 : in
	if !stationary isotropic = false end
	if !isotropic #TODO (need to modify adjacencymatrix() to do this)
		error("Anistropy is not currently implemented (although it is documented in anticipation of future functionality); please contact the package maintainer")
	end
	if !stationary #TODO (need to modify adjacencymatrix() to do this)
		error("Nonstationarity is not currently implemented (although it is documented anticipation of future functionality); please contact the package maintainer")
	end
	w = map(1:w_channels) do _
		_spatialMLP(isotropic, stationary, d, w_dim, w_width, w_g, w_init)
	end
	w = w_channels == 1 ? w[1] : Parallel(vcat, w...)

    SpatialGraphConv(Γ1, Γ2, b, w, g, aggr)
end
function (l::SpatialGraphConv)(g::GNNGraph)
	Z = :Z ∈ keys(g.ndata) ? g.ndata.Z : first(values(g.ndata)) 
	if l.glob 
		@ignore_derivatives GNNGraph(g, gdata = (g.gdata..., R = l(g, Z)))
	else 
		@ignore_derivatives GNNGraph(g, ndata = (g.ndata..., Z = l(g, Z)))
	end
end
function (l::SpatialGraphConv)(g::GNNGraph, x::M) where M <: AbstractMatrix{T} where {T}
	l(g, reshape(x, size(x, 1), 1, size(x, 2)))
end
function (l::SpatialGraphConv)(g::GNNGraph, x::A) where A <: AbstractArray{T, 3} where {T}

    check_num_nodes(g, x)
	
	# Number of independent replicates
	m = size(x, 2)

	# Extract spatial information (typically the spatial distance between neighbours)
	# and coerce to three-dimensional array 
	s = :e ∈ keys(g.edata) ? g.edata.e : permutedims(g.graph[3]) 
	if isa(s, Matrix)
		s = reshape(s, size(s, 1), 1, size(s, 2))
	end

	# Compute T₁(S)
	msg1 = apply_edges((l, xi, xj, e) -> l.ψ(e) , g, l, nothing, nothing, s)
	if l.glob 
		# average over the entire data set (not the replicates, however)
		# note that we use reduce_edges, which, for a batched graph g, returns the 
		# graph-wise aggregation of the edge features 
		t₁ = reduce_edges(mean, g, msg1)  # equivalent to mean(msg1, dims = 3) in the case of a single graph
	else 
		t₁ = aggregate_neighbors(g, mean, msg1)  # average over each neighbourhood 
		
	end 
	t₁ = repeat(t₁, 1, m, 1) # repeat to match the number of independent replicates (NB memory inefficient)

	# Compute T₂(Z, S) 
	w = l.w(s) # spatial weights 
	w = repeat(w, 1, m, 1)       # repeat to match the number of independent replicates (NB memory inefficient)
	# TODO replace with parameterised function f(Zᵢ, Zⱼ), which will be stored in l (see https://carlolucibello.github.io/GraphNeuralNetworks.jl/dev/api/conv/#GraphNeuralNetworks.EdgeConv)
	# TODO l will also be passed in when we do the above change 
	msg2 = apply_edges((xi, xj, e) -> e .* (xi - xj).^2, g, x, x, w)         
	if l.glob 
		t₂ = reduce_edges(mean, g, msg2)
	else 
		t₂ = aggregate_neighbors(g, mean, msg2) # average over each neighbourhood 
	end 

	# Concatenate T₁(S) and T₂(Z, S) 
	t = vcat(t₁, t₂)

	# Map T₁(S) and T₂(Z, S) into final summary statistics 
	l.ρ(t) 
end
function Base.show(io::IO, l::SpatialGraphConv)
	#TODO update 
    # in_channel  = size(l.Γ1, ndims(l.Γ1))
    # out_channel = size(l.Γ1, ndims(l.Γ1)-1)
    # print(io, "SpatialGraphConv(", in_channel, " => ", out_channel)
    # l.g == identity || print(io, ", ", l.g)
    # print(io, ", aggr=", l.a)
    # print(io, ")")
	"hi"
end

function _spatialMLP(isotropic, stationary, d, dim, width, g, init)
	if isotropic
		Chain(
			Dense(1 => w_width, w_g, init = w_init),
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	elseif stationary 
		Chain(
			Dense(d => w_width, w_g, init = w_init),
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	else
		Chain(
			Bilinear((d, d) => w_width, w_g, init = w_init),  
			Dense(w_width => w_dim, w_g, init = w_init)
			)
	end 
end

#TODO document if I ever end up using this
struct GraphSkipConnection{T} <: GNNLayer
	layers::T
end
@layer GraphSkipConnection
function (skip::GraphSkipConnection)(g::GNNGraph)
  h = skip.layers(g)
  x = cat(h.ndata.Z, g.ndata.Z; dims = 1)
  @ignore_derivatives GNNGraph(g, ndata = (g.ndata..., Z = x))
end
function Base.show(io::IO, b::GraphSkipConnection)
  print(io, "GraphSkipConnection(", b.layers, ")")
end

# ---- Clustering ----

"""
	computeclusters(S::Matrix)
Computes hierarchical clusters based on K-means.

# Examples
```
# random set of locations
d = 2
n = 5000
S = rand(d, n)
computeclusters(S)
```
"""
function computeclusters(S::Matrix)

	# Note that if we just want random initial values, we can simply do:
	# K = [16, 4, 1]
	# permutedims(reduce(hcat, assignments.(kmeans.(Ref(S), K))))

	# To construct a grid of initial points, we needsquare numbers when d = 1,
	# cubic numbers when d=3, quartic numbers when d=4, etc.
	d = size(S, 1)
	K = d ∈ [1, 2] ? [16, 4, 1] : (1:3).^d #TODO try with just one cluster layer
	clusterings = map(K) do k
		# Compute initial seeds
		# Partition the domain in a consistent way, so that the spatial
		# relationship is predictable/consistent. Do this using the keyword
		# argument "init", which allows an integer vector of length kc that provides
		# the indices of points to use as initial seeds. So, we just provide the
		# inital points as a grid based on S, where the grid ordering is consistent.
		# The resulting clusters should then roughly align with this grid each time
		# a new set of locations is given.
		if k == 1
			τ = [0.5]
		else
			τ = (0:isqrt(k)-1)/(isqrt(k)-1)
		end
		S_quantiles = quantile.(eachrow(S), Ref(τ))
		init_points = permutedims(expandgrid(S_quantiles...))
		init = map(eachcol(init_points)) do s
			partialsortperm(vec(sum(abs.(S .- s), dims = 1)), 1)
		end
		# S[:, init] # points that will be used as initial cluster points
		@suppress_err assignments(kmeans(S, k; init = init))
	end
	permutedims(reduce(hcat, clusterings))
end

@doc raw"""
	SpatialPyramidPool(aggr)

Spatial pyramid pooling [(He et al., 2014)(https://arxiv.org/abs/1406.4729)]
adapted to graphical data. 

Clusterings are stored as a matrix with $n$ columns, where each row
corresponds to a clustering at a different resolutions (each spatial
location belongs to a single cluster in a given resolution). The clusterings
can be stored in the graph object (so that the clustering algorithm need
only be called once for a given set of locations); if clusterings is not
present in the graph object, the layer will compute the clusterings
automatically (this is less efficient since the clusterings cannot be stored
for later use).

# Examples
```
using NeuralEstimators, Statistics

# Constants across the examples
q = 1   # univariate data
m = 5   # number of independent replicates
d = 2   # spatial dimension, D ⊂ ℜ²
layer = SpatialGraphConv(q => 16)
pool  = SpatialPyramidPool(mean)

# Spatial locations fixed for all replicates
n = 100
S = rand(n, d)
Z = rand(n, m)
g = spatialgraph(S, Z)
h = layer(g)
r = pool(h)

# Spatial locations varying between replicates
n = rand(50:100, m)
S = rand.(n, d)
Z = rand.(n)
g = spatialgraph(S, Z)
h = layer(g)
r = pool(h)
```
"""
struct SpatialPyramidPool{F} <: GNNLayer
    aggr::F
end
@layer SpatialPyramidPool
function (l::SpatialPyramidPool)(g::GNNGraph)

	@assert :clusterings ∈ keys(g.ndata) # could compute clusterings here, but more efficient not to plus it makes things more complicated

	# Input Z is an nₕ x m x n array, where nₕ is the number of hidden features of
	# each node in the final propagation layer
	Z = :Z ∈ keys(g.ndata) ? g.ndata.Z : first(values(g.ndata))

	# Extract clusterings, a cxn matrix with cᵣ the number of cluster resolutions
	clusterings = g.ndata.clusterings

	# Pool the features over the clusterings
	if g.num_graphs == 1
		R = poolfeatures(Z, clusterings, l.aggr)
	else
		R = map(1:g.num_graphs) do i
			# NB getgraph() is very slow, don't use it here
			node_idx = findall(i .== g.graph_indicator)
			poolfeatures(Z[:, :, node_idx], clusterings[:, node_idx], l.aggr)
		end
		R = reduce(hcat, R)
	end

	# R is a Cnₕ x m matrix where C is the total number of clusters across all
	# clustering resolutions. It is now ready to be passed to the aggregation
	# function of the DeepSets architecture. Note that we cannot store R in
	# g.gdata, since it must have last dimension equal to the number of graphs
	# (we can leave the singleton dimension if we want to do this).
    return R
end
Base.show(io::IO, l::SpatialPyramidPool) = print(io, "\nSpatialPyramidPool with aggregation function $(l.aggr)")

function poolfeatures(Z, clusterings, aggr)
	R = map(eachrow(clusterings)) do clustering
		K = maximum(clustering)
		r = map(1:K) do k
			idx = findall(k .== clustering)
			h = Z[:, :, idx]
			aggr(h, dims = 3)
		end
		reduce(vcat, r)
	end
	R = reduce(vcat, R)
	R = dropdims(R; dims = 3)
end

# ---- Universal pooling layer ----

@doc raw"""
    UniversalPool(ψ, ϕ)
Pooling layer (i.e., readout layer) from the paper ['Universal Readout for Graph Convolutional Neural Networks'](https://ieeexplore.ieee.org/document/8852103).
It takes the form,
```math
\boldsymbol{V} = ϕ(|G|⁻¹ \sum_{s\in G} ψ(\boldsymbol{h}_s)),
```
where ``\boldsymbol{V}`` denotes the summary vector for graph ``G``,
``\boldsymbol{h}_s`` denotes the vector of hidden features for node ``s \in G``,
and `ψ` and `ϕ` are dense neural networks.

See also the pooling layers available from [`GraphNeuralNetworks.jl`](https://carlolucibello.github.io/GraphNeuralNetworks.jl/stable/api/pool/).

# Examples
```julia
using NeuralEstimators, Flux, GraphNeuralNetworks
using Graphs: random_regular_graph

# Construct an input graph G
n_h     = 16  # dimension of each feature node
n_nodes = 10
n_edges = 4
G = GNNGraph(random_regular_graph(n_nodes, n_edges), ndata = rand(Float32, n_h, n_nodes))

# Construct the pooling layer
n_t = 32  # dimension of the summary vector for each node
n_v = 64  # dimension of the final summary vector V
ψ = Dense(n_h, n_t)
ϕ = Dense(n_t, n_v)
pool = UniversalPool(ψ, ϕ)

# Apply the pooling layer
pool(G)
```
"""
struct UniversalPool{G,F}
    ψ::G
    ϕ::F
end
@layer UniversalPool
function (l::UniversalPool)(g::GNNGraph, x::AbstractArray)
    u = reduce_nodes(mean, g, l.ψ(x))
    t = l.ϕ(u)
    return t
end
(l::UniversalPool)(g::GNNGraph) = GNNGraph(g, gdata = l(g, node_features(g)))
Base.show(io::IO, D::UniversalPool) = print(io, "\nUniversal pooling layer:\nInner network ψ ($(nparams(D.ψ)) parameters):  $(D.ψ)\nOuter network ϕ ($(nparams(D.ϕ)) parameters):  $(D.ϕ)")


@doc raw"""
	GNNSummary(propagation, readout; globalfeatures = nothing)

A graph neural network (GNN) module designed to serve as the summary network `ψ`
in the [`DeepSet`](@ref) representation when the data are graphical (e.g.,
irregularly observed spatial data).

The `propagation` module transforms graphical input data into a set of
hidden-feature graphs. The `readout` module aggregates these feature graphs into
a single hidden feature vector of fixed length (i.e., a vector of summary
statistics). The summary network is then defined as the composition of the
propagation and readout modules.

Optionally, one may also include a module that extracts features directly 
using all information stored in the graph simultaneously, through the keyword 
argument `globalfeatures`. This module, when applied to a `GNNGraph`, should 
return a matrix of features. TODO explain the dimenson of the feature matrix 

The data should be stored as a `GNNGraph` or `Vector{GNNGraph}`, where
each graph is associated with a single parameter vector. The graphs may contain
subgraphs corresponding to independent replicates.

# Examples
```
using NeuralEstimators, Flux, GraphNeuralNetworks
using Flux: batch
using Statistics: mean

# Propagation module
d = 1      # dimension of response variable
nₕ = 32    # dimension of node feature vectors
propagation = GNNChain(GraphConv(d => nₕ), GraphConv(nₕ => nₕ))

# Readout module
readout = GlobalPool(mean)
nᵣ = nₕ   # dimension of readout vector

# Summary network
ψ = GNNSummary(propagation, readout)

# Inference network
p = 3     # number of parameters in the statistical model
w = 64    # width of hidden layer
ϕ = Chain(Dense(nᵣ, w, relu), Dense(w, p))

# Construct the estimator
θ̂ = DeepSet(ψ, ϕ)

# Apply the estimator to a single graph, a single graph with subgraphs
# (corresponding to independent replicates), and a vector of graphs
# (corresponding to multiple data sets each with independent replicates)
g₁ = rand_graph(11, 30, ndata=rand(d, 11))
g₂ = rand_graph(13, 40, ndata=rand(d, 13))
g₃ = batch([g₁, g₂])
θ̂(g₁)
θ̂(g₃)
θ̂([g₁, g₂, g₃])
```
"""
struct GNNSummary{F, G, H}
	propagation::F   # propagation module
	readout::G       # readout module
	globalfeatures::H
end
GNNSummary(propagation, readout; globalfeatures = nothing) = GNNSummary(propagation, readout, globalfeatures)
@layer GNNSummary
Base.show(io::IO, D::GNNSummary) = print(io, "\nThe propagation and readout modules of a graph neural network (GNN), with a total of $(nparams(D)) trainable parameters:\n\nPropagation module ($(nparams(D.propagation)) parameters):  $(D.propagation)\n\nReadout module ($(nparams(D.readout)) parameters):  $(D.readout)")

function (ψ::GNNSummary)(g::GNNGraph)

	# Propagation module
	h = ψ.propagation(g)

	# Readout module, computes a fixed-length vector (a summary statistic) for each replicate
	# R is a matrix with:
	# nrows = number of summary statistics
	# ncols = number of independent replicates
	if isa(ψ.readout, SpatialPyramidPool)
		R = ψ.readout(h)
	else
		# Standard pooling layers
		Z = :Z ∈ keys(h.ndata) ? h.ndata.Z : first(values(h.ndata))
		R = ψ.readout(h, Z)
	end

	if !isnothing(ψ.globalfeatures)
		R₂ = ψ.globalfeatures(g)
		if isa(R₂, GNNGraph)
			#TODO add assertion that there is data stored in gdata @assert  "The `globalfeatures` field of a `GNNSummary` object must return either an array or a graph with a non-empty field `gdata`"
			R₂ = first(values(R₂.gdata)) #TODO maybe want to enforce that it has an appropriate name (e.g., R)
		end
		R = vcat(R, R₂)
	end

	# reshape from three-dimensional array to matrix 
	R = reshape(R, size(R, 1), :) #TODO not ideal to do this here, I think, makes the output of summarystatistics() quite confusing. (keep in mind the behaviour of summarystatistics on a vector of graphs and a single graph) 

	return R
end
# Code from GNN example:
# θ = sample(1)
# g = simulate(θ, 7)[1]
# ψ(g)
# θ = sample(2)
# # g = simulate(θ, 1:10) # TODO errors! Currently not allowed to have data sets with differing number of independent replicates
# g = simulate(θ, 5)
# g = Flux.batch(g)
# ψ(g)

# ---- Adjacency matrices ----

#TODO why is the fixed adjacencymatrix(S::Matrix, k::Integer) still having self loops? 
@doc raw"""
	adjacencymatrix(S::Matrix, k::Integer; maxmin = false, combined = false)
	adjacencymatrix(S::Matrix, r::AbstractFloat)
	adjacencymatrix(S::Matrix, r::AbstractFloat, k::Integer; random = true)
	adjacencymatrix(M::Matrix; k, r, kwargs...)

Computes a spatially weighted adjacency matrix from spatial locations `S` based 
on either the `k`-nearest neighbours of each location; all nodes within a disc of fixed radius `r`;
or, if both `r` and `k` are provided, a subset of `k` neighbours within a disc
of fixed radius `r`.

Several subsampling strategies are possible when choosing a subset of `k` neighbours within 
a disc of fixed radius `r`. If `random=true` (default), the neighbours are randomly selected from 
within the disc (note that this also approximately preserves the distribution of 
distances within the neighbourhood set). If `random=false`, a deterministic algorithm is used 
that aims to preserve the distribution of distances within the neighbourhood set, by choosing 
those nodes with distances to the central node corresponding to the 
$\{0, \frac{1}{k}, \frac{2}{k}, \dots, \frac{k-1}{k}, 1\}$ quantiles of the empirical 
distribution function of distances within the disc. 
(This algorithm in fact yields $k+1$ neighbours, since both the closest and furthest nodes are always included.) 
Otherwise, 

If `maxmin=false` (default) the `k`-nearest neighbours are chosen based on all points in
the graph. If `maxmin=true`, a so-called maxmin ordering is applied,
whereby an initial point is selected, and each subsequent point is selected to
maximise the minimum distance to those points that have already been selected.
Then, the neighbours of each point are defined as the `k`-nearest neighbours
amongst the points that have already appeared in the ordering. If `combined=true`, the 
neighbours are defined to be the union of the `k`-nearest neighbours and the 
`k`-nearest neighbours subject to a maxmin ordering. 

If `S` is a square matrix, it is treated as a distance matrix; otherwise, it
should be an $n$ x $d$ matrix, where $n$ is the number of spatial locations
and $d$ is the spatial dimension (typically $d$ = 2). In the latter case,
the distance metric is taken to be the Euclidean distance. Note that use of a 
maxmin ordering currently requires a matrix of spatial locations (not a distance matrix).

By convention with the functionality in `GraphNeuralNetworks.jl` which is based on directed graphs, 
the neighbours of location `i` are stored in the column `A[:, i]` where `A` is the 
returned adjacency matrix. Therefore, the number of neighbours for each location is
given by `collect(mapslices(nnz, A; dims = 1))`, and the number of times each node is 
a neighbour of another node is given by `collect(mapslices(nnz, A; dims = 2))`.

# Examples
```
using NeuralEstimators, Distances, SparseArrays

n = 250
d = 2
S = rand(Float32, n, d)
k = 10
r = 0.10

# Memory efficient constructors
adjacencymatrix(S, k)
adjacencymatrix(S, k; maxmin = true)
adjacencymatrix(S, k; maxmin = true, combined = true)
adjacencymatrix(S, r)
adjacencymatrix(S, r, k)
adjacencymatrix(S, r, k; random = false)

# Construct from full distance matrix D
D = pairwise(Euclidean(), S, dims = 1)
adjacencymatrix(D, k)
adjacencymatrix(D, r)
adjacencymatrix(D, r, k)
adjacencymatrix(D, r, k; random = false)
```
"""
function adjacencymatrix(M::Matrix; k::Union{Integer, Nothing} = nothing, r::Union{F, Nothing} = nothing, kwargs...) where F <: AbstractFloat
	# convenience keyword-argument function, used internally by spatialgraph()
	if isnothing(r) & isnothing(k)
		error("One of k or r must be set")
	elseif isnothing(r) 
		adjacencymatrix(M, k; kwargs...)
	elseif isnothing(k)
		adjacencymatrix(M, r)
	else
		adjacencymatrix(M, r, k; kwargs...)
	end
end

function adjacencymatrix(M::Mat, r::F, k::Integer; random::Bool = true) where Mat <: AbstractMatrix{T} where {T, F <: AbstractFloat}

	@assert k > 0
	@assert r > 0

	if random == false
		A = adjacencymatrix(M, r) 
		A = subsetneighbours(A, k)
		A = dropzeros!(A) # remove self loops
		return A 
	end 

	I = Int64[]
	J = Int64[]
	V = T[]
	n = size(M, 1)
	m = size(M, 2)

	for i ∈ 1:n
		sᵢ = M[i, :]
		kᵢ = 0
		iter = shuffle(collect(1:n)) # shuffle to prevent weighting observations based on their ordering in M
		for j ∈ iter
			if i != j # add self loops after construction, to ensure consistent number of neighbours
				if m == n # square matrix, so assume M is a distance matrix
					dᵢⱼ = M[i, j]
				else  # rectangular matrix, so assume S is a matrix of spatial locations
					sⱼ  = M[j, :]
					dᵢⱼ = norm(sᵢ - sⱼ)
				end
				if dᵢⱼ <= r
					push!(I, i)
					push!(J, j)
					push!(V, dᵢⱼ)
					kᵢ += 1
				end
			end
			if kᵢ == k 
				break 
			end
		end
	end
	A = sparse(J,I,V,n,n)
	A = dropzeros!(A) # remove self loops 
	return A
end
adjacencymatrix(M::Mat, k::Integer, r::F) where Mat <: AbstractMatrix{T} where {T, F <: AbstractFloat} = adjacencymatrix(M, r, k)

function adjacencymatrix(M::Mat, k::Integer; maxmin::Bool = false, moralise::Bool = false, combined::Bool = false) where Mat <: AbstractMatrix{T} where T

	@assert k > 0

	if combined 
		a1 = adjacencymatrix(M, k; maxmin = false, combined = false)
		a2 = adjacencymatrix(M, k; maxmin = true, combined = false) 
		A = a1 + (a1 .!= a2) .* a2 
		# add diagonal elements so that each node is considered its own neighbour
		for i ∈ 1:size(A, 1)
			A[i, i] = one(T)  # make element structurally nonzero
			A[i, i] = zero(T) # set to zero
		end
		return A 
	end

	I = Int64[]
	J = Int64[]
	V = T[]
	n = size(M, 1)
	m = size(M, 2)

	if m == n # square matrix, so assume M is a distance matrix
		D = M
	else      # otherwise, M is a matrix of spatial locations
		S = M
		# S = S + 50 * eps(T) * rand(T, size(S, 1), size(S, 2)) # add some random noise to break ties
	end

	if k >= n # more neighbours than observations: return a dense adjacency matrix
		if m != n
			D = pairwise(Euclidean(), S')
		end
		A = sparse(D)
	elseif !maxmin
		k += 1 # each location neighbours itself, so increase k by 1
		for i ∈ 1:n

			if m == n
				d = D[i, :]
			else
				# Compute distances between sᵢ and all other locations
				d = colwise(Euclidean(), S', S[i, :])
			end

			# Find the neighbours of s
			j, v = findneighbours(d, k)
 
			push!(I, repeat([i], inner = k)...)
			push!(J, j...)
			push!(V, v...)
		end
		A = sparse(J,I,V,n,n) # NB the neighbours of location i are stored in the column A[:, i]
	else
		@assert m != n "`adjacencymatrix` with maxmin-ordering requires a matrix of spatial locations, not a distance matrix"
		ord     = ordermaxmin(S)          # calculate ordering
		Sord    = S[ord, :]               # re-order locations
		NNarray = findorderednn(Sord, k)  # find k nearest neighbours/"parents"
		R = builddag(NNarray, T)          # build DAG
		A = moralise ?  R' * R : R        # moralise

		# Add distances to A
		# TODO This is memory inefficient, especially for large n; only optimise if we find that this approach works well and this is a bottleneck
		D = pairwise(Euclidean(), Sord')
		I, J, V = findnz(A)
		indices = collect(zip(I,J))  
		indices = CartesianIndex.(indices)
		A.nzval .= D[indices]

		# "unorder" back to the original ordering
		# Sanity check: Sord[sortperm(ord), :] == S
		# Sanity check: D[sortperm(ord), sortperm(ord)] == pairwise(Euclidean(), S')
		A = A[sortperm(ord), sortperm(ord)]
	end

	return A
end

## helper functions
deletecol!(A,cind) = SparseArrays.fkeep!(A,(i,j,v) -> j != cind)
findnearest(A::AbstractArray, x) = argmin(abs.(A .- x))
findnearest(V::SparseVector, q) = V.nzind[findnearest(V.nzval, q)] # efficient version for SparseVector that doesn't materialise a dense array
function selfloops!(A)
	#TODO export function, and replace previous documentation:
	# By convention, we consider a location to neighbour itself and, hence,
	# `k`-neighbour methods will yield `k`+1 neighbours for each location. Note that
	# one may use `dropzeros!()` to remove these self-loops from the constructed
	# adjacency matrix (see below).

	
	# add diagonal elements so that each node is considered its own neighbour
	T = eltype(A)
	for i ∈ 1:size(A, 1)
		A[i, i] = one(T)  # make element structurally nonzero
		A[i, i] = zero(T) # set to zero
	end
	return A
end
function subsetneighbours(A, k) 

	τ = [i/k for i ∈ 0:k] # probability levels (k+1 values)
	n = size(A, 1)

	# drop self loops 
	dropzeros!(A)
	for j ∈ 1:n 
		Aⱼ = A[:, j] # neighbours of node j 
		if nnz(Aⱼ) > k+1 # if there are fewer than k+1 neighbours already, we don't need to do anything 
			# compute the empirical τ-quantiles of the nonzero entries in Aⱼ
			quantiles = quantile(nonzeros(Aⱼ), τ) 
			# zero-out previous neighbours in Aⱼ
			deletecol!(A, j) 
			# find the entries in Aⱼ that are closest to the empirical quantiles 
			for q ∈ quantiles
				i = findnearest(Aⱼ, q)
				v = Aⱼ[i]
				A[i, j] = v
			end 
		end
	end
	A = dropzeros!(A) # remove self loops TODO Don't think is needed, since we already dropped them 
	return A
end


# Number of neighbours 

# # How it should be:
# s = [1,1,2,2,2,3,4,4,5,5]
# t = [2,3,1,4,5,3,2,5,2,4]
# v = [-5,-5,2,2,2,3,4,4,5,5]
# g = GNNGraph(s, t, v; ndata = (Z = ones(1, 5), )) #TODO shouldn't need to specify name Z
# A = adjacency_matrix(g)
# @test A == sparse(s, t, v)

# l = SpatialGraphConv(1 => 1, identity; aggr = +, bias = false) 
# l.w.β .= ones(Float32, 1)
# l.Γ1  .= zeros(Float32, 1)
# l.Γ2  .= ones(Float32, 1)
# node_features(l(g)) 

# # First node:
# i = 1
# ρ = exp.(l.w.β) # positive range parameter
# d = [A[2, i]]
# e = exp.(-d ./ ρ)
# sum(e)

# # Second node:
# i = 2
# ρ = exp.(l.w.β) # positive range parameter
# d = [A[1, i], A[4, i], A[5, i]]
# e = exp.(-d ./ ρ)
# sum(e)


# using NeuralEstimators, Distances, SparseArrays
# import NeuralEstimators: adjacencymatrix, ordermaxmin, findorderednn, builddag, findneighbours
# n = 5000
# d = 2
# S = rand(Float32, n, d)
# k = 10
# @elapsed adjacencymatrix(S, k; maxmin = true) # 10 seconds
# @elapsed adjacencymatrix(S, k) # 0.3 seconds
#
# @elapsed ord = ordermaxmin(S) # 0.57 seconds
# Sord    = S[ord, :]
# @elapsed NNarray = findorderednn(Sord, k) # 9 seconds... this is the bottleneck
# @elapsed R = builddag(NNarray)  # 0.02 seconds

function adjacencymatrix(M::Mat, r::F) where Mat <: AbstractMatrix{T} where {T, F <: AbstractFloat}

	@assert r > 0

	n = size(M, 1)
	m = size(M, 2)

	if m == n # square matrix, so assume M is a distance matrix, D:
		D = M
		A = D .< r # bit-matrix specifying which locations are within a disc or r

		# replace non-zero elements of A with the corresponding distance in D
		indices = copy(A)
		A = convert(Matrix{T}, A)
		A[indices] = D[indices]

		# convert to sparse matrix
		A = sparse(A)
	else
		S = M
		I = Int64[]
		J = Int64[]
		V = T[]
		for i ∈ 1:n
			# Compute distances between s and all other locations
			s = S[i, :]
			d = colwise(Euclidean(), S', s)

			# Find the r-neighbours of s
			j = d .< r
			j = findall(j)
			push!(I, repeat([i], inner = length(j))...)
			push!(J, j...)
			push!(V, d[j]...)
		end
		A = sparse(I,J,V,n,n)
	end

	A = dropzeros!(A) # remove self loops

	return A
end

function findneighbours(d, k::Integer)
	V = partialsort(d, 1:k)
	J = [findall(v .== d) for v ∈ V]
	J = reduce(vcat, J)
	J = unique(J)
	J = J[1:k] # in the event of ties, there can be too many elements in J, so use only the first 1:k
    return J, V 
end

# TODO this function is much, much slower than the R version... need to optimise
function getknn(S, s, k; args...)
  tree = KDTree(S; args...)
  nn_index, nn_dist = knn(tree, s, k, true)
  nn_index = hcat(nn_index...) |> permutedims # nn_index = stackarrays(nn_index, merge = false)'
  nn_dist  = hcat(nn_dist...)  |> permutedims # nn_dist  = stackarrays(nn_dist, merge = false)'
  nn_index, nn_dist
end

function ordermaxmin(S)

  # get number of locs
  n = size(S, 1)
  k = isqrt(n)
  # k is number of neighbors to search over
  # get the past and future nearest neighbors
  NNall = getknn(S', S', k)[1]
  # pick a random ordering
  index_in_position = [sample(1:n, n, replace = false)..., repeat([missing],1*n)...]
  position_of_index = sortperm(index_in_position[1:n])
  # loop over the first n/4 locations
  # move an index to the end if it is a
  # near neighbor of a previous location
  curlen = n
  nmoved = 0
  for j ∈ 2:2n
	nneigh = round(min(k, n /(j-nmoved+1)))
    nneigh = Int(nneigh)
   if !ismissing(index_in_position[j])
      neighbors = NNall[index_in_position[j], 1:nneigh]
      if minimum(skipmissing(position_of_index[neighbors])) < j
        nmoved += 1
        curlen += 1
        position_of_index[ index_in_position[j] ] = curlen
        rassign(index_in_position, curlen, index_in_position[j])
        index_in_position[j] = missing
    	end
  	end
  end
  ord = collect(skipmissing(index_in_position))

  return ord
end

# rowMins(X) = vec(mapslices(minimum, X, dims = 2))
# colMeans(X) = vec(mapslices(mean, X, dims = 1))
# function ordermaxmin_slow(S)
# 	n = size(S, 1)
# 	D = pairwise(Euclidean(), S')
# 	## Vecchia sequence based on max-min ordering: start with most central location
#   	vecchia_seq = [argmin(D[argmin(colMeans(D)), :])]
#   	for j in 2:n
#     	vecchia_seq_new = (1:n)[Not(vecchia_seq)][argmax(rowMins(D[Not(vecchia_seq), vecchia_seq, :]))]
# 		rassign(vecchia_seq, j, vecchia_seq_new)
# 	end
#   return vecchia_seq
# end

function rassign(v::AbstractVector, index::Integer, x)
	@assert index > 0
	if index <= length(v)
		v[index] = x
	elseif index == length(v)+1
		push!(v, x)
	else
		v = [v..., fill(missing, index - length(v) - 1)..., x]
	end
	return v
end

function findorderednnbrute(S, k::Integer)
  # find the k+1 nearest neighbors to S[j,] in S[1:j,]
  # by convention, this includes S[j,], which is distance 0
  n = size(S, 1)
  k = min(k,n-1)
  NNarray = Matrix{Union{Integer, Missing}}(missing, n, k+1)
  for j ∈ 1:n
	d = colwise(Euclidean(), S[1:j, :]', S[j, :])
    NNarray[j, 1:min(k+1,j)] = sortperm(d)[1:min(k+1,j)]
  end
  return NNarray
end

function findorderednn(S, k::Integer)

  # number of locations
  n = size(S, 1)
  k = min(k,n-1)
  mult = 2

  # to store the nearest neighbor indices
  NNarray = Matrix{Union{Integer, Missing}}(missing, n, k+1)

  # find neighbours of first mult*k+1 locations by brute force
  maxval = min( mult*k + 1, n )
  NNarray[1:maxval, :] = findorderednnbrute(S[1:maxval, :],k)

  query_inds = min( maxval+1, n):n
  data_inds = 1:n
  ksearch = k
  while length(query_inds) > 0
    ksearch = min(maximum(query_inds), 2ksearch)
    data_inds = 1:min(maximum(query_inds), n)
	NN = getknn(S[data_inds, :]', S[query_inds, :]', ksearch)[1]

    less_than_l = hcat([NN[l, :] .<= query_inds[l] for l ∈ 1:size(NN, 1)]...) |> permutedims
	sum_less_than_l = vec(mapslices(sum, less_than_l, dims = 2))
    ind_less_than_l = findall(sum_less_than_l .>= k+1)
	NN_k = hcat([NN[l,:][less_than_l[l,:]][1:(k+1)] for l ∈ ind_less_than_l]...) |> permutedims
    NNarray[query_inds[ind_less_than_l], :] = NN_k

    query_inds = query_inds[Not(ind_less_than_l)]
  end

  return NNarray
end

function builddag(NNarray, T = Float32)
  n, k = size(NNarray)
  I = [1]
  J = [1]
  V = T[1] 
  for j in 2:n
    i = NNarray[j, :]
    i = collect(skipmissing(i))
    push!(J, repeat([j], length(i))...)
    push!(I, i...)
	push!(V, repeat([1], length(i))...)
  end
  R = sparse(I,J,V,n,n)
  return R
end


# n=100
# S = rand(n, 2)
# k=5
# ord = ordermaxmin(S)              # calculate maxmin ordering
# Sord = S[ord, :];                 # reorder locations
# NNarray = findorderednn(Sord, k)  # find k nearest neighbours/"parents"
# R = builddag(NNarray)             # build the DAG
# Q = R' * R                        # moralise



"""
	maternclusterprocess(; λ=10, μ=10, r=0.1, xmin=0, xmax=1, ymin=0, ymax=1, unit_bounding_box=false)

Simulates a Matérn cluster process with density of parent Poisson point process
`λ`, mean number of daughter points `μ`, and radius of cluster disk `r`, over the
simulation window defined by `xmin` and `xmax`, `ymin` and `ymax`.

If `unit_bounding_box` is `true`, then the simulated points will be scaled so that
the longest side of their bounding box is equal to one (this may change the simulation window). 

See also the R package
[`spatstat`](https://cran.r-project.org/web/packages/spatstat/index.html),
which provides functions for simulating from a range of point processes and
which can be interfaced from Julia using
[`RCall`](https://juliainterop.github.io/RCall.jl/stable/).

# Examples
```
using NeuralEstimators

# Simulate a realisation from a Matérn cluster process
S = maternclusterprocess()

# Visualise realisation (requires UnicodePlots)
using UnicodePlots
scatterplot(S[:, 1], S[:, 2])

# Visualise realisations from the cluster process with varying parameters
n = 250
λ = [10, 25, 50, 90]
μ = n ./ λ
plots = map(eachindex(λ)) do i
	S = maternclusterprocess(λ = λ[i], μ = μ[i])
	scatterplot(S[:, 1], S[:, 2])
end
```
"""
function maternclusterprocess(; λ = 10, μ = 10, r = 0.1, xmin = 0, xmax = 1, ymin = 0, ymax = 1, unit_bounding_box::Bool=false)

	#Extended simulation windows parameters
	rExt=r #extension parameter -- use cluster radius
	xminExt=xmin-rExt
	xmaxExt=xmax+rExt
	yminExt=ymin-rExt
	ymaxExt=ymax+rExt
	#rectangle dimensions
	xDeltaExt=xmaxExt-xminExt
	yDeltaExt=ymaxExt-yminExt
	areaTotalExt=xDeltaExt*yDeltaExt #area of extended rectangle

	#Simulate Poisson point process
	numbPointsParent=rand(Poisson(areaTotalExt*λ)) #Poisson number of points

	#x and y coordinates of Poisson points for the parent
	xxParent=xminExt.+xDeltaExt*rand(numbPointsParent)
	yyParent=yminExt.+yDeltaExt*rand(numbPointsParent)

	#Simulate Poisson point process for the daughters (ie final poiint process)
	numbPointsDaughter=rand(Poisson(μ),numbPointsParent)
	numbPoints=sum(numbPointsDaughter) #total number of points

	#Generate the (relative) locations in polar coordinates by
	#simulating independent variables.
	theta=2*pi*rand(numbPoints) #angular coordinates
	rho=r*sqrt.(rand(numbPoints)) #radial coordinates

	#Convert polar to Cartesian coordinates
	xx0=rho.*cos.(theta)
	yy0=rho.*sin.(theta)

	#replicate parent points (ie centres of disks/clusters)
	xx=vcat(fill.(xxParent, numbPointsDaughter)...)
	yy=vcat(fill.(yyParent, numbPointsDaughter)...)

	#Shift centre of disk to (xx0,yy0)
	xx=xx.+xx0
	yy=yy.+yy0

	#thin points if outside the simulation window
	booleInside=((xx.>=xmin).&(xx.<=xmax).&(yy.>=ymin).&(yy.<=ymax))
	xx=xx[booleInside]
	yy=yy[booleInside]

	S = hcat(xx, yy)

	unit_bounding_box ? unitboundingbox(S) : S
end

"""
#Examples 
```
n = 5
S = rand(n, 2)
unitboundingbox(S)
```
"""
function unitboundingbox(S::Matrix)
	Δs = maximum(S; dims = 1) -  minimum(S; dims = 1)
	r = maximum(Δs) 
	S/r # note that we would multiply range estimates by r
end