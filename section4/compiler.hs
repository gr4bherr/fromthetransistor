{-
gcc compiler
#read source file ~> tokenize ~> parse ~> reduce ~> optimize ~> encode to bytestring ~> write file
soruce code text -> ir code -> machine code
1. lexer
2. ast
3. parser
4. intermidiate representation (assembly better)

compilation:
gcc -S test.c
assembly:
gcc -c 
-}

import System.IO

main :: IO ()
main = do 
       infile <- openFile "c-testsuite/tests/single-exec/00001.c" ReadMode
       outfile <- openFile "mytests/00001.txt" WriteMode
       mainloop infile outfile
       hClose infile
       hClose outfile

mainloop :: Handle -> Handle -> IO ()
mainloop infile outfile = do
  hasline <- hIsEOF infile
  if not hasline
     then do inpStr <- hGetLine infile
             hPutStrLn outfile inpStr
             mainloop infile outfile
     else return ()
