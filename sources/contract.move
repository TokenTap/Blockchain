module moduleaddr::recipes {
    use std::signer;
    use std::vector;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::option;
    use aptos_framework::managed_coin;

    struct User has copy, drop, store {
        email: String,
        name: String,
        created_at: u128,
    }

    struct Recipe has copy, drop, store {
        title: String,
        description: String,
        images: vector<String>,
        id: u64,
        created_at: u128,
        email: String,
    }

    struct Appreciation has copy, drop, store {
        id: u64,
        recipe_id: u64,
        email: String,
        created_at: u128,
    }

    struct RecipeFullInfo has copy, drop, store {
        name: String,
        recipe: Recipe,
        appreciation_count: u64,
    }

    struct UpvoteCoin has copy, drop, store {}

    public entry fun initialize(account: &signer) {
        managed_coin::initialize<UpvoteCoin>(
            account,
            b"UpvoteCoin",    // name
            b"UPC",            // symbol
            6,                 // decimals
            true               // can mint
        );
    }

    struct UsersList has key {
        elements: vector<User>,
        count: u64,
    }

    struct RecipesList has key {
        elements: vector<Recipe>,
        count: u64,
    }

    struct AppreciationsList has key {
        elements: vector<Appreciation>,
        count: u64,
    }

    public entry fun create_user_list(account: &signer) { // this function creates am empty list of users
        let addr = signer::address_of(account);
        assert!(!exists<UsersList>(addr), 1);
        move_to(account, UsersList { elements: vector::empty<User>(), count: 0 });
    }

    public entry fun create_list(account: &signer) { // this function creates am empty list of recipes
        let addr = signer::address_of(account);
        assert!(!exists<RecipesList>(addr), 1);
        move_to(account, RecipesList { elements: vector::empty<Recipe>(), count: 0 });
    }

    public entry fun create_appreciation_list(account: &signer) {
        let addr = signer::address_of(account);
        assert!(!exists<AppreciationsList>(addr), 1);
        move_to(account, AppreciationsList { elements: vector::empty<Appreciation>(), count: 0 });
    }

    public entry fun login_user(account: &signer, email: String, name: String) acquires UsersList {
        let addr = signer::address_of(account);
        assert!(exists<UsersList>(addr), 2);
        let list = borrow_global_mut<UsersList>(addr);
        let elements = &list.elements;
        let len = vector::length(elements);
        let i=0;
        while (i < len) {
            let user_ref = vector::borrow(elements, i);
            if (user_ref.email == email) {
                abort 40;
            };
            i = i + 1;
        };
        let created_at: u128 = (timestamp::now_microseconds() as u128);
        let user = User {
            email,
            name,
            created_at
        };
        vector::push_back(&mut list.elements, user);
        list.count = list.count + 1;
    }

    #[view]
    public fun get_all_recipes(addr: address): vector<RecipeFullInfo> acquires RecipesList, UsersList, AppreciationsList {
        assert!(exists<RecipesList>(addr), 2);
        let list = borrow_global<RecipesList>(addr);
        let user_list = borrow_global<UsersList>(addr);
        let appreciation_list = borrow_global<AppreciationsList>(addr);
        let elements = &list.elements;
        let len = vector::length(elements);
        let i=0;
        let recipes: vector<RecipeFullInfo> = vector::empty<RecipeFullInfo>();
        while (i < len) {
            let recipe_ref = vector::borrow(elements, i);
            let appreciation_count: u64 = 0;
            let j=0;
            let app_len = vector::length(&appreciation_list.elements);
            while (j < app_len) {
                let app_ref = vector::borrow(&appreciation_list.elements, j);
                if (app_ref.recipe_id == recipe_ref.id) {
                    appreciation_count = appreciation_count + 1;
                };
                j = j + 1;
            };
            j=0;
            let user_len = vector::length(&user_list.elements);
            let name: String = utf8(b"");
            while (j < user_len) {
                let user_ref = vector::borrow(&user_list.elements, j);
                if (user_ref.email == recipe_ref.email) {
                    name = user_ref.name;
                    break;
                };
                j = j + 1;
            };
            let recipe_full_info = RecipeFullInfo {
                name,
                recipe: *recipe_ref,
                appreciation_count,
            };
            vector::push_back(&mut recipes, recipe_full_info);
            i = i + 1;
        };
        recipes
    }

    #[view]
    public fun get_all_appreciations(addr: address): vector<Appreciation> acquires AppreciationsList {
        assert!(exists<AppreciationsList>(addr), 2);
        let list = borrow_global<AppreciationsList>(addr);
        list.elements
    }

    public entry fun add_recipe(account: &signer, title: String, description: String, images: vector<String>, email: String) acquires RecipesList {
        let addr = signer::address_of(account);
        assert!(exists<RecipesList>(addr), 3);
        let list = borrow_global_mut<RecipesList>(addr);
        let id = list.count;
        let created_at: u128 = (timestamp::now_microseconds() as u128);
        let recipe = Recipe {
            title,
            description,
            images,
            id,
            created_at,
            email,
        };
        vector::push_back(&mut list.elements, recipe);
        list.count = list.count + 1;
    }

    public fun get_recipe_by_id(addr: address, id: u64): option::Option<RecipeFullInfo> acquires RecipesList, UsersList, AppreciationsList {
        assert!(exists<RecipesList>(addr), 4);
        let list = borrow_global<RecipesList>(addr);
        let user_list = borrow_global<UsersList>(addr);
        let appreciation_list = borrow_global<AppreciationsList>(addr);
        let elements = &list.elements;
        let len = vector::length(elements);
        let i=0;
        while (i < len) {
            let recipe_ref = vector::borrow(elements, i);
            if (recipe_ref.id == id) {
                let appreciation_count: u64 = 0;
                let j=0;
                let app_len = vector::length(&appreciation_list.elements);
                while (j < app_len) {
                    let app_ref = vector::borrow(&appreciation_list.elements, j);
                    if (app_ref.recipe_id == recipe_ref.id) {
                        appreciation_count = appreciation_count + 1;
                    };
                    j = j + 1;
                };
                j=0;
                let user_len = vector::length(&user_list.elements);
                let name: String = utf8(b"");
                while (j < user_len) {
                    let user_ref = vector::borrow(&user_list.elements, j);
                    if (user_ref.email == recipe_ref.email) {
                        name = user_ref.name;
                        break;
                    };
                    j = j + 1;
                };
                let recipe_full_info = RecipeFullInfo {
                    name,
                    recipe: *recipe_ref,
                    appreciation_count,
                };
                return option::some<RecipeFullInfo>(recipe_full_info);
            };
            i = i + 1;
        };
        return option::none<RecipeFullInfo>()
    }

    public entry fun appreciate_and_mint(account: &signer, recipe_id: u64, email: String) acquires AppreciationsList, RecipesList {
        let addr = signer::address_of(account);
        let list = borrow_global_mut<AppreciationsList>(addr);
        let recipe_list = borrow_global<RecipesList>(addr);
        let recipes = &recipe_list.elements;
        let len = vector::length(recipes);
        let i=0;
        while (i < len) {
            let recipe_ref = vector::borrow(recipes, i);
            if (recipe_ref.email == email) {
                abort 40;
            };
            i = i + 1;
        };
        i=0;
        while(i < vector::length(&list.elements)) {
            let app_ref = vector::borrow(&list.elements, i);
            if (app_ref.recipe_id == recipe_id && app_ref.email == email) {
                abort 41;
            };
            i = i + 1;
        };
        let created_at: u128 = (timestamp::now_microseconds() as u128);
        let appreciation_id = list.count;
        managed_coin::mint<UpvoteCoin>(account, addr, 10);
        let appreciation = Appreciation {
            id: appreciation_id,
            recipe_id,
            email,
            created_at,
        };
        vector::push_back(&mut list.elements, appreciation);
        list.count = list.count + 1;
    }

    public entry fun mint_coin(account: &signer) {
        managed_coin::mint<UpvoteCoin>(account, signer::address_of(account), 10);
    }
}