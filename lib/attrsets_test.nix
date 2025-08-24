{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  lib = import ./attrsets.nix pkgs;
in
{
  testConcatOfList = {
    description = "Concatenates multiple arrays within a double array into a single array.";
    expr =
      let
        testData = [
          [
            "a"
            "b"
            "c"
          ]
          [
            "d"
            "e"
            "f"
          ]
        ];
      in
      lib.concatOfList testData;
    expected = [
      "a"
      "b"
      "c"
      "d"
      "e"
      "f"
    ];
  };
  testConcatOfAttrs = {
    description = "Concatenates multiple attrset within a attrset into a single attrset.";
    expr =
      let
        testData = [
          {
            a = "a";
            b = "b";
            c = "c";
          }
          {
            d = "d";
            e = "e";
            f = "f";
          }
        ];
      in
      lib.concatOfAttrs testData;
    expected = {
      a = "a";
      b = "b";
      c = "c";
      d = "d";
      e = "e";
      f = "f";
    };
  };
  targetAttrsValue = {
    testAttrInList = {
      description = "targetAttrsValue. attr in list";
      expr =
        let
          testData = {
            abc = [
              "a"
              "b"
              "c"
            ];
            def = [
              "d"
              "e"
              "f"
            ];
            ghi = [
              "g"
              "h"
              "i"
            ];
            jkl = [
              "j"
              "k"
              "l"
            ];
          };
        in
        lib.targetAttrsValue [
          "abc"
          "ghi"
        ] testData;
      expected = [
        [
          "a"
          "b"
          "c"
        ]
        [
          "g"
          "h"
          "i"
        ]
      ];
    };
    testAttrInAttrs = {
      description = "targetAttrsValue. attr in attrs";
      expr =
        let
          testData = {
            abc = {
              a = "a";
              b = "b";
              c = "c";
            };
            def = {
              d = "d";
              e = "e";
              f = "f";
            };
            ghi = {
              g = "g";
              h = "h";
              i = "i";
            };
            jkl = {
              j = "j";
              k = "k";
              l = "l";
            };
          };
        in
        lib.targetAttrsValue [
          "abc"
          "ghi"
        ] testData;
      expected = [
        {
          a = "a";
          b = "b";
          c = "c";
        }
        {
          g = "g";
          h = "h";
          i = "i";
        }
      ];
    };
  };
}
