import System.IO

--ghc compiler.hs && ./compiler && ./test.py

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