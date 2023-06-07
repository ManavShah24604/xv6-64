#include "user.h"
#include "../kernel/types.h"
#include "../kernel/stat.h"

int main(int fir,char **sec)
{
    trace(atoi(sec[1]));
    exec(sec[2],&sec[2]);
    return 0;
}