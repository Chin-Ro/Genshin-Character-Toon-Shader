#ifndef GENSHIN_HELPS
#define GENSHIN_HELPS
half Remap(half x, half t1, half t2, half s1, half s2)
{
    return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
}
#endif