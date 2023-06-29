import ProcTypes;




function Word moutValue(PIndx rfAddr1, PIndx wb0Addr1, PIndx wb1Addr1, PIndx wb2Addr1, PIndx wb3Addr1,
        Word rfValue1, Word wb0Value1, Word wb1Value1, Word wb2Value1, Word wb3Value1);
        Word retOut=0;
    if(rfAddr1==0) begin
        retOut=0;
    end
    else begin
        if(rfAddr1==wb0Addr1) begin
            retOut=wb0Value1;
        end
        else if(rfAddr1==wb1Addr1) begin
            retOut=wb1Value1;
        end
        else if(rfAddr1==wb2Addr1) begin
            retOut=wb2Value1;
        end
        else if(rfAddr1==wb3Addr1) begin
            retOut=wb3Value1;
        end
        else begin
            retOut=rfValue1;
        end
    end
    return retOut;
endfunction

