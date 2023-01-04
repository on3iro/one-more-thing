use one_more_thing::get_random_things;
use rand::{thread_rng, Rng};

fn main() {
    let result = get_random_things(&vec!["a".to_string(), "b".to_string()], 1, |max| {
        let index: u16 = thread_rng().gen_range(0..(u16::try_from(max).unwrap_or(0)));
        index
    })
    .unwrap();

    println!("Result: {}", result.retrieved_things[0]);
}
