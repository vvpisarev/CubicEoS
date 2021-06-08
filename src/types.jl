abstract type AbstractEoSComponent end

abstract type AbstractEoSMixture end

const NothingOrT{T} = Union{Nothing,T}

struct BrusilovskyEoSComponent{T<:Number} <: AbstractEoSComponent
    # meta information
    name::String

    # physical parameters
    Pc::T  # critical pressure
    acentric_factor::T
    RTc::T   # R * critical temperature
    molar_mass::T  # [kg mol⁻¹] molar mass
    carbon_number::Int  # [dimless] number of carbons

    # eos parameters
    ac::T     # explicit coefficient of the eos a_c
    b::T      # explicit coefficient of the eos b
    c::T      # explicit coefficient of the eos c
    d::T      # explicit coefficient of the eos d
    Psi::T    # primary coefficient of the eos - \Psi

    function BrusilovskyEoSComponent{T}(
        ;
        name::AbstractString="No Name",
        critical_pressure::Number=NaN,
        critical_temperature::Number=NaN,
        acentric_factor::Number=NaN,
        Omegac::Number=NaN,
        Zc::Number=NaN,
        Psi::Number=NaN,
        molar_mass::Number=NaN,
        carbon_number::Integer=0,
        kw...
    ) where {T}
        alpha = Omegac^3
        beta = Zc + Omegac - 1.0
        ds = sqrt(Omegac - 0.75)
        sigma = -Zc + Omegac * (0.5 + ds)
        delta = -Zc + Omegac * (0.5 - ds)
        RTc = GAS_CONSTANT_SI * critical_temperature
        rtp = RTc / critical_pressure
        ac = alpha * RTc * rtp
        b = beta * rtp
        c = sigma * rtp
        d = delta * rtp
        new{T}(
            name,
            critical_pressure,
            acentric_factor,
            RTc,
            molar_mass,
            carbon_number,
            ac, b, c, d, Psi
        )
    end
end
BrusilovskyEoSComponent(; x...) = BrusilovskyEoSComponent{Float64}(; x...)

Base.eltype(::BrusilovskyEoSComponent{T}) where {T} = T

for func in (:molar_mass, :name, :carbon_number)
    expr = :($(func)(c::BrusilovskyEoSComponent) = getfield(c, $(QuoteNode(func))))
    eval(expr)
    eval(:(export $func))
end

#=
Mixture
=#

struct BrusilovskyEoSMixture{T} <: AbstractEoSMixture
    components::Vector{BrusilovskyEoSComponent{T}}

    eij::Matrix{T} # constant  thermal binary interaction coefficient
    gij::Matrix{T} # linear    thermal binary interaction coefficient
    hij::Matrix{T} # quadratic thermal binary interaction coefficient

    function BrusilovskyEoSMixture( ;
        components::AbstractVector{BrusilovskyEoSComponent{T}},
        constant::AbstractMatrix,
        linear::AbstractMatrix,
        quadratic::AbstractMatrix,
        kw...
    ) where {T}
        new{T}(components, constant, linear, quadratic)
    end
end

@inline Base.@propagate_inbounds function Base.getindex(
    mix::BrusilovskyEoSMixture,
    i::Integer
)
    return mix.components[i]
end

struct BrusilovskyThermoBuffer{T}
    matr::Matrix{T}
    vec1::Vector{T}
    vec2::Vector{T}
end

function BrusilovskyThermoBuffer{T}(n::Integer) where {T}
    matr = Matrix{T}(undef, n, n)
    vec1 = similar(matr, (n,))
    vec2 = similar(vec1)
    return BrusilovskyThermoBuffer{T}(matr, vec1, vec2)
end

BrusilovskyThermoBuffer(n::Integer) = BrusilovskyThermoBuffer{Float64}(n)

function BrusilovskyThermoBuffer(mix::BrusilovskyEoSMixture{T}) where {T}
    nc = ncomponents(mix)
    return BrusilovskyThermoBuffer{T}(nc)
end

thermo_buffer(mix::BrusilovskyEoSMixture) = BrusilovskyThermoBuffer(mix)
