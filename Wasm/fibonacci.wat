(module
  (memory 1)
  (func $main (local i32 i32 i32 i32 f32)
    (set_local 0 (i32.const 0))
    (set_local 1 (i32.const 1))
    (set_local 2 (i32.const 1))
    (set_local 3 (i32.const 0))
    (set_local 4 (f32.const 56.8))
    
    (block
    (loop
        (br_if 1 (i32.gt_s (get_local 0) (i32.const 5)))
        (set_local 3 (get_local 2))
        (set_local 2 (i32.add (get_local 2) (get_local 1)))
        (set_local 1 (get_local 3))
        (set_local 0 (i32.add (get_local 0) (i32.const 1)))
        (br 0)
    )
    )
    (i32.store (i32.const 0) (get_local 2))
  )
  (start $main)
  (data (i32.const 0) "0000")
)
