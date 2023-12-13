#include <stdlib.h>
#include <stdio.h>

struct Entity {
    int size;
    void **components;
};

typedef struct Entity* E;

struct Registry {
    int size;
    int cap;
    E *arr; //Array where slot = ent pointer
};

typedef struct Registry* T;

//Expands the list and returns a new one 
T expand(T list) {
    list->cap = list->cap * 2 + 2;
    list->arr = realloc(list->arr, list->cap * sizeof(void *));
    if (list->arr == NULL) {
        fprintf(stderr, "error: memory reallocation failed");
    }
    
    printf("Expanded list\n");
    return list;      
}

//inits a new list 
T init() {
    T list = malloc(sizeof(*list));
    list->size = 0;
    list->cap = 0;
    list->arr = NULL;
    return list;
}

//Adds a new spawned entity to the list  
void add(T list, E entity) {
    if (list->size == list->cap) {
        expand(list);
    }
    (list->arr)[list->size] = entity;
    list->size++;
    
    //TODO: remove 
    printf("list size: %d\n", list->size);
}

/*
 * Returns a list of all entities that match all components queried
 * Assumes list is a list of entities 
 */
T query(T registry, int *component_list, int size) {
    
    T res = init();

    for(int i = 0; i < registry->size; i++) {
        E ent = registry->arr[i];
    
        int should_add = 1;
        for (int c = 0; c < size; c++) {
            if (ent->components[component_list[c]] == NULL) {
            //    add = 0;
            //    break;
            //}
            //void *component = ((void **)(ent->components))[component_list[c]];
            //if (component == NULL) {
                should_add = 0;
                break;
            }
        }
        if(should_add)
            add(res, ent);
        
    }

    return res;
}

/*
* Tests
*/


struct Position {
    float x;
    float y;
};

struct Color {
    char *color;
};

typedef struct Position* P;
typedef struct Color* C;


int main() {

    T list = init();

    P pos = malloc(sizeof(*pos));
    pos->x = 23.4;
    pos->y = 2.564;
    C col = malloc(sizeof(*col));
    col->color = "RED";

    //the entity
    E ent = malloc(sizeof(*ent)); //has components 0 and 2
    ent->size = 3;
    ent->components = malloc(sizeof(void*) * 3);
    ent->components[0] = pos;
    ent->components[1] = NULL;
    ent->components[2] = col;

    E ent2 = malloc(sizeof(*ent));
    ent2->size = 3;
    ent2->components = malloc(sizeof(void*) * 3);
    ent2->components[0] = NULL;
    ent2->components[1] = NULL;
    ent2->components[2] = col;

    
    //Add
    for (int i = 0; i < 500; i++)
        add(list, ent);

    for (int i = 0; i < 5; i++)
        add(list, ent2);

    //query 
    int *a = malloc(sizeof(int) * 1);
    a[0] = 1;
    // a[1] = 2; 

    T res = query(list, a, 1);

    printf("size of query res is %d\n", res->size);
}