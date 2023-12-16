#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#define MAX_QUERY_SIZE 1024

//TODO: make registry dynamic
//Come up with demo programs 

struct Registry {
    int64_t size;
    int64_t cap;
    void ***arr; //Array where slot = pointer to an entity (void* array)
};

struct QueryResult {
    int64_t size;
    void ***result;
};

typedef struct QueryResult* Q;
struct Registry* registry;

//Expands the list and returns a new one 
void reg_expand() {
    registry->cap = registry->cap * 2 + 2;
    void ***temp = registry->arr;
    registry->arr = malloc(sizeof(void***) * registry->cap);

    for(int i = 0; i < registry->size; i++) {
        registry->arr[i] = temp[i];
    }

    free(temp);
    
    if (registry->arr == NULL) {
        fprintf(stderr, "error: memory reallocation failed");
    }
}

//inits the registry
void reg_init() {
    
    registry = malloc(sizeof(*registry));
    registry->size = 0;
    registry->cap = 0;
    registry->arr = NULL;
}

//Adds a new spawned entity to the list  
void reg_add(void **entity) {
    if (registry->size == registry->cap) {
        reg_expand(registry);
    }
    (registry->arr)[registry->size] = entity;
    registry->size++;
}

Q init_query() {
    Q query_result = malloc(sizeof(*query_result));
    query_result->size = 0;
    query_result->result = malloc(MAX_QUERY_SIZE * sizeof(void**));
    return query_result;
}
/*
 * Returns a list of all entities that match all components queried
 * Assumes registry is a list of entities 
 * Returns the list of entities
 */
Q reg_query(int64_t *component_list, int64_t size) {
   
    Q query_result = init_query();
    //put entities in query result 
    for (int64_t i = 0; i < registry->size; i++) {
        void **ent = registry->arr[i];
    
        int64_t should_add = 1;
        for (int64_t c = 0; c < size; c++) {
            if (ent[component_list[c]] == NULL) {
                should_add = 0;
                break;
            }
        }

        if(should_add) {
            query_result->result[query_result->size] = ent;
            query_result->size++;
        }
        
    }

    return query_result;

    //TODO: what if the list is empty? Segfaults in codegen!
}

// struct Position {
//     float x;
//     float y;
// };

// int main() {
//     reg_init();

//     struct Position* pos = malloc(sizeof(*pos));
//     pos->x = 23.4;
//     pos->y = 2.564;

//     void ** ent = malloc(sizeof(*ent) * 3);
//     ent[0] = NULL;
//     ent[1] = NULL;
//     ent[2] = pos;

//     void ** ent2 = malloc(sizeof(*ent) * 3);
//     ent2[0] = pos;
//     ent2[1] = pos;
//     ent2[2] = NULL;

//     void ** ent3 = malloc(sizeof(*ent) * 3);
//     ent3[0] = NULL;
//     ent3[1] = pos;
//     ent3[2] = pos;

//    reg_add(ent);
//    reg_add(ent2);
//    reg_add(ent3);

//     int* arr = malloc(1 * sizeof(int));
//     arr[0] = 2; //3rd component 
//     Q res = reg_query(arr, 1);
//     printf("size of result array %lld\n", res->size);
//     for (int i = 0; i < res->size; i++) {
//         printf("i: %d\n", i);
//         printf("res->size: %d\n", res->size);
//         void ** ent = res->result[i];
//         struct Position * p = ent[2];
//         printf("x: %f, y: %f\n", p->x, p->y);
//     }
// }