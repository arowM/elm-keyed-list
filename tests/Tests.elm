module Tests exposing (cons, conversions, empty, emptyTestFailureMsg, keyedListFuzzer, push, remove, suite, takeKeys, update)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import KeyedList exposing (..)
import Test exposing (..)


conversions : Test
conversions =
    describe "converting to and from Lists"
        [ fuzz (list int) "should restore the original list" <|
            \fuzzList ->
                fuzzList
                    |> fromList
                    |> toList
                    |> Expect.equal fuzzList
        , fuzz (list int) "generating from a List should preserve length" <|
            \fuzzList ->
                fromList fuzzList
                    |> KeyedList.length
                    |> Expect.equal (List.length fuzzList)
        , test "empty Lists should become empty KeyedLists" <|
            \_ ->
                fromList []
                    |> KeyedList.isEmpty
                    |> Expect.true "KeyedList was not empty"
        ]


keyedListFuzzer : Fuzzer (KeyedList Int)
keyedListFuzzer =
    Fuzz.map fromList (list int)


emptyTestFailureMsg : Bool -> Int -> String
emptyTestFailureMsg isEmpty len =
    let
        lengthString =
            String.fromInt len

        isEmptyQualifier =
            if isEmpty then
                ""

            else
                "not "
    in
    "length == "
        ++ lengthString
        ++ " but list is "
        ++ isEmptyQualifier
        ++ "empty"


empty : Test
empty =
    describe "empty"
        [ fuzz keyedListFuzzer "should be empty iff length = 0" <|
            \fuzzList ->
                let
                    isEmpty =
                        KeyedList.isEmpty fuzzList

                    len =
                        length fuzzList
                in
                (isEmpty && len == 0)
                    || (not isEmpty && len > 0)
                    |> Expect.true (emptyTestFailureMsg isEmpty len)
        ]


cons : Test
cons =
    describe "cons"
        [ fuzz keyedListFuzzer "should increase length by 1" <|
            \fuzzList ->
                KeyedList.cons 9 fuzzList
                    |> KeyedList.length
                    |> Expect.equal (KeyedList.length fuzzList + 1)
        , test "should work on empty KeyedLists" <|
            \_ ->
                KeyedList.cons 1 KeyedList.empty
                    |> KeyedList.toList
                    |> Expect.equal [ 1 ]
        , fuzz keyedListFuzzer "should cons value onto beginning of list" <|
            \fuzzList ->
                KeyedList.cons 9 fuzzList
                    |> toList
                    |> Expect.equal (9 :: toList fuzzList)
        ]


push : Test
push =
    describe "push"
        [ fuzz keyedListFuzzer "should increase length by 1" <|
            \fuzzList ->
                KeyedList.push 9 fuzzList
                    |> KeyedList.length
                    |> Expect.equal (KeyedList.length fuzzList + 1)
        , test "should work on empty KeyedLists" <|
            \_ ->
                KeyedList.push 1 KeyedList.empty
                    |> KeyedList.toList
                    |> Expect.equal [ 1 ]
        , fuzz keyedListFuzzer "should push value onto end of list" <|
            \fuzzList ->
                KeyedList.push 9 fuzzList
                    |> toList
                    |> Expect.equal (toList fuzzList ++ [ 9 ])
        ]


takeKeys : Int -> KeyedList a -> List Key
takeKeys n items =
    let
        keyHelper key _ =
            key
    in
    KeyedList.keyedMap keyHelper items
        |> List.take n


remove : Test
remove =
    describe "remove"
        [ test "should remove items from lists with many items" <|
            \_ ->
                let
                    items =
                        fromList [ 1, 2 ]

                    keys =
                        takeKeys 1 items
                in
                List.foldl KeyedList.remove items keys
                    |> toList
                    |> List.length
                    |> Expect.equal 1
        , test "should remove items from singleton lists" <|
            \_ ->
                let
                    items =
                        fromList [ 1 ]

                    keys =
                        takeKeys 1 items
                in
                List.foldl KeyedList.remove items keys
                    |> toList
                    |> Expect.equal []
        , test "should leave empty lists unchanged" <|
            \_ ->
                let
                    keys =
                        takeKeys 1 <| fromList [ 1 ]
                in
                List.foldl KeyedList.remove KeyedList.empty keys
                    |> toList
                    |> Expect.equal []
        ]


update : Test
update =
    describe "update"
        [ test "should modify items in non-empty lists" <|
            \_ ->
                let
                    items =
                        fromList [ 1, 2, 3 ]

                    keys =
                        takeKeys 2 items
                            |> List.drop 1

                    addTwo n =
                        n + 2

                    updater key =
                        KeyedList.update key addTwo
                in
                List.foldl updater items keys
                    |> toList
                    |> Expect.equal [ 1, 4, 3 ]
        , test "should leave empty lists alone" <|
            \_ ->
                let
                    items =
                        fromList [ 1 ]

                    keys =
                        takeKeys 1 items

                    addTwo n =
                        n + 2

                    updater key =
                        KeyedList.update key addTwo
                in
                List.foldl updater KeyedList.empty keys
                    |> toList
                    |> Expect.equal []
        ]


suite : Test
suite =
    describe "KeyedList module"
        [ conversions
        , empty
        , cons
        , push
        , remove
        , update
        ]
