
/*
* Tests
*/

// struct Position {
//     float x;
//     float y;
// };

// struct Color {
//     char *color;
// };

// typedef struct Position* P;
// typedef struct Color* C;


// int main() {

//     T list = init();

//     P pos = malloc(sizeof(*pos));
//     pos->x = 23.4;
//     pos->y = 2.564;
//     C col = malloc(sizeof(*col));
//     col->color = "RED";

//     //the entity
//     void **ent = malloc(sizeof(*ent) * 3); //has components 0 and 2
//     ent[0] = pos;
//     ent[1] = NULL;
//     ent[2] = col;

//     void **ent2 = malloc(sizeof(*ent) * 3);
//     ent2[0] = NULL;
//     ent2[1] = NULL;
//     ent2[2] = col;

    
//     //Add
//     for (int i = 0; i < 500; i++)
//         add(list, ent);

//     for (int i = 0; i < 5; i++)
//         add(list, ent2);

//     //query 
//     int *a = malloc(sizeof(int) * 1);
//     a[0] = 1;
//     //a[1] = 2; 

//     T res = query(list, a, 1);

//     printf("size of query res is %d\n", res->size);
// }