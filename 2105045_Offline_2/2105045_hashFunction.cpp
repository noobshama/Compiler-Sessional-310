#ifndef HASHFUNCTIONS_CPP
#define HASHFUNCTIONS_CPP

#include <bits/stdc++.h>

enum class HashFunctionType
{
    SDBM,
    Murmur,
    FNV1a

};

// SDBM Hash Function
unsigned int sdbmhash(const std::string &str, unsigned int bucket_sizes)
{
    unsigned int hash = 0;
    for (size_t i = 0; i < str.length(); i++)
    {
        hash = ((str[i]) + (hash << 6) + (hash << 16) - hash) % bucket_sizes;
    }
    return hash;
}

// SECOND Hash Function
unsigned int SimpleMurmurHash(const std::string &str, unsigned int bucket_sizes)
{
    unsigned int hash = 0x9747b28c; // Seed value
    for (char c : str)
    {
        hash ^= (unsigned char)c;
        hash *= 0x5bd1e995;
        hash ^= hash >> 15;
    }
    return hash % bucket_sizes;
}


unsigned int FNV1aHash(const std::string &str, unsigned int bucket_sizes)
{
    const unsigned int fnv_prime = 16777619u;
    unsigned int hash = 2166136261u;

    for (char c : str)
    {
        hash ^= (unsigned char)c;
        hash *= fnv_prime;
    }

    return hash % bucket_sizes;
}

// Function to return the selected hash function
unsigned int (*getHashFunction(HashFunctionType type))(const std::string &, unsigned int)
{
    switch (type)
    {
    case HashFunctionType::SDBM:

        return sdbmhash;

    case HashFunctionType::Murmur:

        return SimpleMurmurHash;

    case HashFunctionType::FNV1a:

        return FNV1aHash;

    default:

        return sdbmhash; // Default to SDBM
        
    }
}

#endif
