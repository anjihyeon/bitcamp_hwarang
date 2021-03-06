<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt"%>
<%@ include file="../layout/menu.jsp"%>
<%@ include file="../layout/rightUser.jsp"%>

<c:set var="contextPath" value="${pageContext.request.contextPath}" />
<!-- 주문자 휴대폰 번호 -->
<c:set var="orderer_hp" value="" />
<!-- 최종 결제 금액 -->
<c:set var="final_total_order_price" value="0" />

<!-- 총주문 금액 -->
<c:set var="total_order_price" value="0" />
<!-- 총 상품수 -->
<c:set var="total_order_goods_qty" value="0" />
<!-- 총할인금액 -->
<c:set var="total_discount_price" value="0" />
<!-- 총 배송비 -->
<c:set var="total_delivery_price" value="0" />

<!DOCTYPE html>
<html>
<head>
<!-- jQuery -->
<script type="text/javascript"
	src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
<!-- iamport.payment.js -->
<script type="text/javascript"
	src="https://cdn.iamport.kr/js/iamport.payment-1.1.5.js"></script>
<style>
#layer {
	z-index: 2;
	position: absolute;
	top: 0px;
	left: 0px;
	width: 100%;
	/* background-color:rgba(0,0,0,0.8); */
}
#popup_order_detail {
	z-index: 3;
	position: fixed;
	text-align: center;
	left: 10%;
	top: 0%;
	width: 60%;
	height: 100%;
	background-color: #ccff99;
	border: 2px solid #0000ff;
}
#close {
	z-index: 4;
	float: right;
}
#myTable{
	 background-color: #ccffff;
	 width: 80%;
	 padding: 30px;
	 height: 100px;
	 table-layout: fixed;
	 font-size: 17px;
}
#list_view{
	 width: 50%;
	 padding: 50xp;
	 table-layout: fixed;
}
</style>

<script src="http://dmaps.daum.net/map_js_init/postcode.v2.js"></script>
<script>
	function execDaumPostcode() {
		new daum.Postcode(
				{
					oncomplete : function(data) {
						// 팝업에서 검색결과 항목을 클릭했을때 실행할 코드를 작성하는 부분.
						// 도로명 주소의 노출 규칙에 따라 주소를 조합한다.
						// 내려오는 변수가 값이 없는 경우엔 공백('')값을 가지므로, 이를 참고하여 분기 한다.
						var fullRoadAddr = data.roadAddress; // 도로명 주소 변수
						var extraRoadAddr = ''; // 도로명 조합형 주소 변수
						// 법정동명이 있을 경우 추가한다. (법정리는 제외)
						// 법정동의 경우 마지막 문자가 "동/로/가"로 끝난다.
						if (data.bname !== '' && /[동|로|가]$/g.test(data.bname)) {
							extraRoadAddr += data.bname;
						}
						// 건물명이 있고, 공동주택일 경우 추가한다.
						if (data.buildingName !== '' && data.apartment === 'Y') {
							extraRoadAddr += (extraRoadAddr !== '' ? ', '
									+ data.buildingName : data.buildingName);
						}
						// 도로명, 지번 조합형 주소가 있을 경우, 괄호까지 추가한 최종 문자열을 만든다.
						if (extraRoadAddr !== '') {
							extraRoadAddr = ' (' + extraRoadAddr + ')';
						}
						// 도로명, 지번 주소의 유무에 따라 해당 조합형 주소를 추가한다.
						if (fullRoadAddr !== '') {
							fullRoadAddr += extraRoadAddr;
						}
						// 우편번호와 주소 정보를 해당 필드에 넣는다.
						document.getElementById('zipcode').value = data.zonecode; //5자리 새우편번호 사용
						document.getElementById('roadAddress').value = fullRoadAddr;
						document.getElementById('jibunAddress').value = data.jibunAddress;
						// 사용자가 '선택 안함'을 클릭한 경우, 예상 주소라는 표시를 해준다.
						if (data.autoRoadAddress) {
							//예상되는 도로명 주소에 조합형 주소를 추가한다.
							var expRoadAddr = data.autoRoadAddress
									+ extraRoadAddr;
							document.getElementById('guide').innerHTML = '(예상 도로명 주소 : '
									+ expRoadAddr + ')';
						} else if (data.autoJibunAddress) {
							var expJibunAddr = data.autoJibunAddress;
							document.getElementById('guide').innerHTML = '(예상 지번 주소 : '
									+ expJibunAddr + ')';
						} else {
							document.getElementById('guide').innerHTML = '';
						}
					}
				}).open();
	}
	
	var IMP = window.IMP; // 생략해도 괜찮습니다.
	IMP.init("imp88213691"); // "imp00000000" 대신 발급받은 "가맹점 식별코드"를 사용합니다.
	function requestPay() {
		// IMP.request_pay(param, callback) 호출
		IMP.request_pay({ // param
			pg : "inicis",
			pay_method : "card",
			merchant_uid : "${member.member_id}",
			name : '${funding.funding_subject}',
			amount : ${funding.funding_price},
			buyer_email : "${member.member_email}",
			buyer_name : "${member.member_name}",
			buyer_tel : "${member.member_phonenum}",
			buyer_addr : "${member.member_address}",
		}, function(rsp) { // callback
			if (rsp.success) {
				// 결제 성공 시 로직,
				alert("결제 완료되었습니다. 나의 페이지에서 확인 가능합니다.")
			} else {
				// 결제 실패 시 로직,
				alert("결제가 취소되었습니다.")
			}
		});
	}


	$(document).ready(function(){

	    update_amounts();
	    $('.qty').change(function() {
	        update_amounts();
	    });
	    
	function update_amounts()
	{
	    var sum = 0.0;
	    $('#myTable > tbody  > tr:not(:last)').each(function() {
	        var qty = parseFloat($(this).find('.qty').val() || 0,10);
	        var price = parseFloat($(this).find('.price').val() || 0,10);
	        var amount = (qty*price)
	        sum+=amount;
	        $(this).find('.amount').text(''+amount);
	    });
	    //just update the total to sum  
	    $('input.total').val(sum);
	}
	});//]]> 
</script>
</head>
<title>결제페이지</title>

	<form action="orderResult" method="post" name="order" id="order" style="padding-right: 15%; padding-left: 15%;   ">
	<H1>1.펀딩정보</H1>
		<table class="list_view" id="list_view">
			<tbody align=center >
				<tr style="background: #33ff00">
					<td colspan=2 class="fixed">주문상품</td>
					<td>수량</td>
					<td>상품 가격</td>
					<td>합계</td>
				</tr>
				<tr>
						<td class="funding_image"><a href="${contextPath}/funding/fundingView?funding_num=${funding.funding_num}">
						<img width="200" alt="" src="${funding.funding_image }">
						<input type="hidden" id="order_image" name="order_image" value="${funding.funding_image}" /> 
						</a></td>
						<td>
							<h2>
								<a href="${pageContext.request.contextPath}/goods/goods.do?command=goods_detail&goods_id=${item.goods_id }">${item.goods_title }</A>
								<input type="hidden" id="order_name" name="order_name" value="${funding.funding_subject}" />
							</h2>
						</td>
						<td>
							<h2>1개<h2>
							<input type="hidden" id="order_rec" name="order_rec" value="${order.order_rec}" />
						</td>
						<td><h2>${funding.funding_price}(원)</h2>
						<input type="hidden" id="order_price" name="order_price" value="${funding.funding_price}" /></td>
						<td>
							<h2> ${1 * funding.funding_price}원</h2> 
							<input type="hidden" id="order_price" name="order_price" value="${order.order_qty * order.order_price}" />
						</td>
				</tr>
			</tbody>
		</table>
		<div class="clear"></div>

		<br> <br>
		<H1>2.배송지 정보</H1>
		<DIV class="detail_table">
			<table>
				<tbody>
					<tr class="dot_line">
						<td class="fixed_join">배송방법</td>
						<td><input type="radio" id="delivery_method" name="delivery_method" value="핸드폰" checked>핸드폰&nbsp;&nbsp;&nbsp; 
							<input type="radio" id="delivery_method" name="delivery_method" value="카카오톡">카카오톡&nbsp;&nbsp;&nbsp; 
							<input type="radio" id="delivery_method" name="delivery_method" value="이메일">이메일&nbsp;&nbsp;&nbsp; 
					</tr>
					<tr class="dot_line">
						<td class="fixed_join">배송지 선택</td>
						<td><input type="radio" name="delivery_place"onClick="restore_all()" value="기본배송지" checked>기본배송지&nbsp;&nbsp;&nbsp; 
						<input type="radio" name="delivery_place" value="새로입력" onClick="reset_all()">새로입력&nbsp;&nbsp;&nbsp; 
						<input type="radio" name="delivery_place" value="최근배송지">최근배송지 &nbsp;&nbsp;&nbsp;</td>
					</tr>
					<tr class="dot_line">
						<td class="fixed_join">받으실 분${member.member_id}</td>
						<td><input id="receiver_name" name="receiver_name" type="text" size="40" value="${member.member_name}"/> 
						<input type="hidden" id="member_id" name="member_id" value="${member.member_id}" /> 
						<input type="hidden" id="h_receiver_name" name="h_receiver_name" value="${orderer.member_name }" /></td>
					</tr>
					<tr class="dot_line">
						<td class="fixed_join">휴대폰번호</td>
						<td>
						<select id="hp1" name="hp1">
								<option>없음</option>
								<option value="010" selected>010</option>
								<option value="011">011</option>
								<option value="016">016</option>
								<option value="017">017</option>
								<option value="018">018</option>
								<option value="019">019</option>
						</select> - <input size="10px" type="text" id="hp2" name="hp2"
							value="${orderer.hp2 }"> - <input size="10px" type="text"
							id="hp3" name="hp3" value="${orderer.hp3 }"><br>
						<br> 
						<input type="hidden" id="h_hp1" name="h_hp1" value="${orderer.hp1 }" />
						<input type="hidden" id="h_hp2" name="h_hp2" value="${orderer.hp2 }" /> 
						<input type="hidden" id="h_hp3" name="h_hp3" value="${orderer.hp3 }" /> 
							<c:set var="orderer_hp" value="${orderer.hp1}-${orderer.hp2}-${orderer.hp3 }" />
					</tr>
					
					<tr class="dot_line">
						<td class="fixed_join">주소</td>
						<td><input type="text" id="zipcode" name="zipcode" size="5"
							value="${orderer.zipcode }"> <a
							href="javascript:execDaumPostcode()">우편번호검색</a> <br>
							<p>
								지번 주소:<br> 
								<input type="text" id="roadAddress"name="roadAddress" size="50" value="${orderer.roadAddress }" /><br>
								<br> 도로명 주소: 
								<input type="text" id="jibunAddress"name="jibunAddress" size="50" value="${orderer.jibunAddress }" /><br>
								<br> 나머지 주소: 
								<input type="text" id="namujiAddress"name="namujiAddress" size="50"value="${orderer.namujiAddress }" />
							</p> 
							<input type="hidden" id="h_zipcode" name="h_zipcode"value="${orderer.zipcode }" /> 
							<input type="hidden"id="h_roadAddress" name="h_roadAddress"value="${orderer.roadAddress }" />
							<input type="hidden"id="h_jibunAddress" name="h_jibunAddress"value="${orderer.jibunAddress }" /> 
							<input type="hidden"id="h_namujiAddress" name="h_namujiAddress"value="${orderer.namujiAddress }" /></td>
					</tr>
					<tr class="dot_line">
						<td class="fixed_join">요청 메시지 </td>
						<td><input id="delivery_message" name="delivery_message"type="text" size="50" placeholder="판매자에게 전달할 메시지를 남겨주세요." /></td>
					</tr>
				</tbody>
			</table>
		</div>
		<div>
			<br>
			<br>
			<h2>3.주문고객</h2>
			<table>
				<tbody>
					<tr class="dot_line">
						<td><h2>이름</h2></td>
						<td><input type="text" value="${member.member_name }" size="15" /></td>
					</tr>
					<tr class="dot_line">
						<td><h2>핸드폰</h2></td>
						<td><input type="text"
							value="${member.member_phonenum }" size="15" />
						</td>
					</tr>
					<tr class="dot_line">
						<td><h2>이메일</h2></td>
						<td><input type="text"
							value="${member.member_email}" size="15" /></td>
					</tr>
				</tbody>
			</table>
		</div>
		<div class="clear"></div>
		<br> <br> <br>
		
		<div class="clear"></div>
		<br>
		
		
<!-- 총주문금액계산 -->
	<table id="myTable">
		<thead>
			<tr>
				<th>아이디</th>
				<th>상품명</th>
				<th>수량</th>
				<th>가격</th>
				<th align="center"><span id="amount" class="amount">총 금액</span>
				</th>
			</tr>
		</thead>
		<tfoot>
			<tr>
				<td colspan="2"></td>
				<td align="right"><span id="total" class="total"></span></td>
			</tr>
		</tfoot>
		<tbody>
			<tr>
				<td>${member.member_id}<input type="hidden" name="member_id" id="member_id" value="${member.member_id}"></td>
				<td>${funding.funding_subject}<input type="hidden" name="order_title" value="${funding.funding_subject}"></td>
				<td><input type="number" min="1" max="100" class="qty" name="order_qty"></td>
				<td>${funding.funding_price }<input type="hidden" value="${funding.funding_price }" class="price" name="order_price"></td>
				<td><span id="amount" class="amount">0</span></td>
			</tr>
			<tr>
				<td></td>
				<td></td>
				<td></td>
			</tr>
		</tbody>
	</table>
	<input type="submit" value="테스트">
</form>
	
		<br> <br> <br>
		<div style="padding-right: 15%;padding-left: 15%;">
			<button onclick="requestPay()" class="btn btn-primary text-right">결제하기</button>
		 <a href="${contextPath}/funding/fundingList"
			class="btn btn-primary text-right">결제취소 </a></div>

<%@include file="../layout/bottom.jsp"%>