#include <stdlib.h>
#include <stdio.h>
#define MAX_QUERY_ARR_SIZE 1024

struct Registry {
    int size;
    int cap;
    void ***arr; //Array where slot = pointer to an entity (void* array)
};

struct QueryResult {
    int size;
    void ***result;
};

typedef struct QueryResult* Q;
struct Registry* registry;
Q query_result;

//Expands the list and returns a new one 
void reg_expand() {
    printf("entered reg_expand\n");
    registry->cap = registry->cap * 2 + 2;
    printf("new cap is %d", registry->cap);
    void ***temp = registry->arr;
    registry->arr = malloc(sizeof(void***) * registry->cap);

    for(int i = 0; i < registry->size; i++) {
        registry->arr[i] = temp[i];
    }

    free(temp);
    
    //realloc(registry->arr, registry->cap * sizeof(void ***));
    printf("finished calling realloc\n");
    if (registry->arr == NULL) {
        fprintf(stderr, "error: memory reallocation failed");
    }
    
    printf("Expanded list\n");
}

//inits the registry
void reg_init() {
    printf("Entering reg_init\n");
    query_result = malloc(sizeof(*query_result));
    query_result->size = 0;
    query_result->result = malloc(MAX_QUERY_ARR_SIZE * sizeof(*(query_result ->result)));
    registry = malloc(sizeof(*registry));
    registry->size = 0;
    registry->cap = 1024;
    registry->arr = malloc(1024 * sizeof(void***));
    printf("Reg init finished\n");
}

//Adds a new spawned entity to the list  
void reg_add(void **entity) {
    printf("entered reg_add\n");
    if (registry->size == registry->cap) {
        reg_expand(registry);
    }
    (registry->arr)[registry->size] = entity;
    registry->size++;
    printf("reg_add finished\n");
}

/*
 * Returns a list of all entities that match all components queried
 * Assumes registry is a list of entities 
 * Returns the list of entities
 */
Q reg_query(int *component_list, int size) {
    printf("entered req_query");

    query_result->size = 0;
    
    //put entities in query result 
    for (int i = 0; i < registry->size; i++) {
        void **ent = registry->arr[i];
    
        int should_add = 1;
        for (int c = 0; c < size; c++) {
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

    fprintf(stdout, "size of query result is %d\n", query_result->size);
    return query_result;

    //TODO: what if the list is empty? Segfaults in codegen!
}