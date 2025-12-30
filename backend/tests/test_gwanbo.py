from app.gwanbo import parse_search_detail_html


SAMPLE_HTML = """
<div class="table_contents_list">
  <div class="title_area">
    <div class="f-l">
      <h4>법률</h4>
      <span class="total_num">총 <strong class="c-blue">2</strong>건 </span>
    </div>
  </div>
  <ul class="list">
    <li>
      <a title="새창열림" href="javascript:void(0)"
         onclick="click_highclass_gwanbo('/ezpdf/customLayout.jsp?contentId=I0000000000000001762506029499000&amp;tocId=I0000000000000001762390935470000&amp;isTocOrder=N','법률제21118호(첨단재생의료 및 첨단바이오의약품 안전 및 지원에 관한 법률 일부개정법률)','21114','법률','2' ,'20251111' , '1','0.1KB');">
        법률제21118호(첨단재생의료 및 첨단바이오의약품 안전 및 지원에 관한 법률 일부개정법률)
      </a>
      <span>2025.11.11</span><span>21114 호</span><span>관보(정호)</span>
    </li>
    <li>
      <a title="새창열림" href="javascript:void(0)"
         onclick="click_highclass_gwanbo('/ezpdf/customLayout.jsp?contentId=I0000000000000001766995549472000&amp;tocId=I0000000000000001766561319642000&amp;isTocOrder=N','법률제21297호(바이오의약품 위탁개발생산 기업 등의 규제지원에 관한 특별법)','21148','법률','2' ,'20251230' , '1','0.1KB');">
        법률제21297호(바이오의약품 위탁개발생산 기업 등의 규제지원에 관한 특별법)
      </a>
      <span>2025.12.30</span><span>21148 호</span><span>관보(정호)</span>
    </li>
  </ul>
</div>

<div class="table_contents_list">
  <div class="title_area">
    <div class="f-l"><h4>공고</h4></div>
  </div>
  <ul class="list">
    <li>
      <a title="새창열림" href="javascript:void(0)"
         onclick="click_highclass_gwanbo('/ezpdf/customLayout.jsp?contentId=I0000000000000001766728813641000&amp;tocId=I0000000000000001766473510993000&amp;isTocOrder=N','기후에너지환경부공고제2025-215호(「2026년 바이오가스 민간의무생산자 고시」제정안 행정예고)','21148','공고','11' ,'20251230' , '1','0.1KB');">
        기후에너지환경부공고제2025-215호(「2026년 바이오가스 민간의무생산자 고시」제정안 행정예고)
      </a>
      <span>2025.12.30</span><span>21148 호</span><span>관보(별권3권)</span>
    </li>
  </ul>
</div>
""".strip()


def test_parse_search_detail_html_extracts_items() -> None:
    items = parse_search_detail_html(SAMPLE_HTML)
    assert len(items) == 3

    first = items[0]
    assert first.section == "법률"
    assert first.published_date == "2025-11-11"
    assert first.gwanbo_issue_no == 21114
    assert first.gwanbo_publication_raw == "관보(정호)"
    assert first.content_id == "I0000000000000001762506029499000"
    assert first.toc_id == "I0000000000000001762390935470000"
    assert first.is_toc_order == "N"
    assert first.pdf_url.startswith("https://www.gwanbo.go.kr/ezpdf/customLayout.jsp?")

    last = items[-1]
    assert last.section == "공고"
    assert last.published_date == "2025-12-30"
    assert last.gwanbo_issue_no == 21148
    assert last.gwanbo_publication_raw == "관보(별권3권)"

