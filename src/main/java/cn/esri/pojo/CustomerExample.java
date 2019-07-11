package cn.esri.pojo;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class CustomerExample {
    private Integer start;
    private Integer rows;

    public Integer getStart() {
        return start;
    }

    public void setStart(Integer start) {
        this.start = start;
    }

    public Integer getRows() {
        return rows;
    }

    public void setRows(Integer rows) {
        this.rows = rows;
    }

    protected String orderByClause;

    protected boolean distinct;

    protected List<Criteria> oredCriteria;

    public CustomerExample() {
        oredCriteria = new ArrayList<Criteria>();
    }

    public void setOrderByClause(String orderByClause) {
        this.orderByClause = orderByClause;
    }

    public String getOrderByClause() {
        return orderByClause;
    }

    public void setDistinct(boolean distinct) {
        this.distinct = distinct;
    }

    public boolean isDistinct() {
        return distinct;
    }

    public List<Criteria> getOredCriteria() {
        return oredCriteria;
    }

    public void or(Criteria criteria) {
        oredCriteria.add(criteria);
    }

    public Criteria or() {
        Criteria criteria = createCriteriaInternal();
        oredCriteria.add(criteria);
        return criteria;
    }

    public Criteria createCriteria() {
        Criteria criteria = createCriteriaInternal();
        if (oredCriteria.size() == 0) {
            oredCriteria.add(criteria);
        }
        return criteria;
    }

    protected Criteria createCriteriaInternal() {
        Criteria criteria = new Criteria();
        return criteria;
    }

    public void clear() {
        oredCriteria.clear();
        orderByClause = null;
        distinct = false;
    }

    protected abstract static class GeneratedCriteria {
        protected List<Criterion> criteria;

        protected GeneratedCriteria() {
            super();
            criteria = new ArrayList<Criterion>();
        }

        public boolean isValid() {
            return criteria.size() > 0;
        }

        public List<Criterion> getAllCriteria() {
            return criteria;
        }

        public List<Criterion> getCriteria() {
            return criteria;
        }

        protected void addCriterion(String condition) {
            if (condition == null) {
                throw new RuntimeException("Value for condition cannot be null");
            }
            criteria.add(new Criterion(condition));
        }

        protected void addCriterion(String condition, Object value, String property) {
            if (value == null) {
                return;
                // throw new RuntimeException("Value for " + property + " cannot be null");
            }
            if(value.equals("")){
                return;
            }
            criteria.add(new Criterion(condition, value));
        }

        protected void addCriterion(String condition, Object value1, Object value2, String property) {
            if (value1 == null || value2 == null) {
                throw new RuntimeException("Between values for " + property + " cannot be null");
            }
            criteria.add(new Criterion(condition, value1, value2));
        }

        public Criteria andCustIdIsNull() {
            addCriterion("cust_id is null");
            return (Criteria) this;
        }

        public Criteria andCustIdIsNotNull() {
            addCriterion("cust_id is not null");
            return (Criteria) this;
        }

        public Criteria andCustIdEqualTo(Long value) {
            addCriterion("cust_id =", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdNotEqualTo(Long value) {
            addCriterion("cust_id <>", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdGreaterThan(Long value) {
            addCriterion("cust_id >", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdGreaterThanOrEqualTo(Long value) {
            addCriterion("cust_id >=", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdLessThan(Long value) {
            addCriterion("cust_id <", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdLessThanOrEqualTo(Long value) {
            addCriterion("cust_id <=", value, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdIn(List<Long> values) {
            addCriterion("cust_id in", values, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdNotIn(List<Long> values) {
            addCriterion("cust_id not in", values, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdBetween(Long value1, Long value2) {
            addCriterion("cust_id between", value1, value2, "custId");
            return (Criteria) this;
        }

        public Criteria andCustIdNotBetween(Long value1, Long value2) {
            addCriterion("cust_id not between", value1, value2, "custId");
            return (Criteria) this;
        }

        public Criteria andCustNameIsNull() {
            addCriterion("cust_name is null");
            return (Criteria) this;
        }

        public Criteria andCustNameIsNotNull() {
            addCriterion("cust_name is not null");
            return (Criteria) this;
        }

        public Criteria andCustNameEqualTo(String value) {
            addCriterion("cust_name =", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameNotEqualTo(String value) {
            addCriterion("cust_name <>", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameGreaterThan(String value) {
            addCriterion("cust_name >", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameGreaterThanOrEqualTo(String value) {
            addCriterion("cust_name >=", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameLessThan(String value) {
            addCriterion("cust_name <", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameLessThanOrEqualTo(String value) {
            addCriterion("cust_name <=", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameLike(String value) {
            addCriterion("cust_name like", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameNotLike(String value) {
            addCriterion("cust_name not like", value, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameIn(List<String> values) {
            addCriterion("cust_name in", values, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameNotIn(List<String> values) {
            addCriterion("cust_name not in", values, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameBetween(String value1, String value2) {
            addCriterion("cust_name between", value1, value2, "custName");
            return (Criteria) this;
        }

        public Criteria andCustNameNotBetween(String value1, String value2) {
            addCriterion("cust_name not between", value1, value2, "custName");
            return (Criteria) this;
        }

        public Criteria andCustUserIdIsNull() {
            addCriterion("cust_user_id is null");
            return (Criteria) this;
        }

        public Criteria andCustUserIdIsNotNull() {
            addCriterion("cust_user_id is not null");
            return (Criteria) this;
        }

        public Criteria andCustUserIdEqualTo(Long value) {
            addCriterion("cust_user_id =", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdNotEqualTo(Long value) {
            addCriterion("cust_user_id <>", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdGreaterThan(Long value) {
            addCriterion("cust_user_id >", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdGreaterThanOrEqualTo(Long value) {
            addCriterion("cust_user_id >=", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdLessThan(Long value) {
            addCriterion("cust_user_id <", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdLessThanOrEqualTo(Long value) {
            addCriterion("cust_user_id <=", value, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdIn(List<Long> values) {
            addCriterion("cust_user_id in", values, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdNotIn(List<Long> values) {
            addCriterion("cust_user_id not in", values, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdBetween(Long value1, Long value2) {
            addCriterion("cust_user_id between", value1, value2, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustUserIdNotBetween(Long value1, Long value2) {
            addCriterion("cust_user_id not between", value1, value2, "custUserId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdIsNull() {
            addCriterion("cust_create_id is null");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdIsNotNull() {
            addCriterion("cust_create_id is not null");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdEqualTo(Long value) {
            addCriterion("cust_create_id =", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdNotEqualTo(Long value) {
            addCriterion("cust_create_id <>", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdGreaterThan(Long value) {
            addCriterion("cust_create_id >", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdGreaterThanOrEqualTo(Long value) {
            addCriterion("cust_create_id >=", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdLessThan(Long value) {
            addCriterion("cust_create_id <", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdLessThanOrEqualTo(Long value) {
            addCriterion("cust_create_id <=", value, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdIn(List<Long> values) {
            addCriterion("cust_create_id in", values, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdNotIn(List<Long> values) {
            addCriterion("cust_create_id not in", values, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdBetween(Long value1, Long value2) {
            addCriterion("cust_create_id between", value1, value2, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustCreateIdNotBetween(Long value1, Long value2) {
            addCriterion("cust_create_id not between", value1, value2, "custCreateId");
            return (Criteria) this;
        }

        public Criteria andCustSourceIsNull() {
            addCriterion("cust_source is null");
            return (Criteria) this;
        }

        public Criteria andCustSourceIsNotNull() {
            addCriterion("cust_source is not null");
            return (Criteria) this;
        }

        public Criteria andCustSourceEqualTo(String value) {
            addCriterion("cust_source =", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceNotEqualTo(String value) {
            addCriterion("cust_source <>", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceGreaterThan(String value) {
            addCriterion("cust_source >", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceGreaterThanOrEqualTo(String value) {
            addCriterion("cust_source >=", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceLessThan(String value) {
            addCriterion("cust_source <", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceLessThanOrEqualTo(String value) {
            addCriterion("cust_source <=", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceLike(String value) {
            addCriterion("cust_source like", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceNotLike(String value) {
            addCriterion("cust_source not like", value, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceIn(List<String> values) {
            addCriterion("cust_source in", values, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceNotIn(List<String> values) {
            addCriterion("cust_source not in", values, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceBetween(String value1, String value2) {
            addCriterion("cust_source between", value1, value2, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustSourceNotBetween(String value1, String value2) {
            addCriterion("cust_source not between", value1, value2, "custSource");
            return (Criteria) this;
        }

        public Criteria andCustIndustryIsNull() {
            addCriterion("cust_industry is null");
            return (Criteria) this;
        }

        public Criteria andCustIndustryIsNotNull() {
            addCriterion("cust_industry is not null");
            return (Criteria) this;
        }

        public Criteria andCustIndustryEqualTo(String value) {
            addCriterion("cust_industry =", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryNotEqualTo(String value) {
            addCriterion("cust_industry <>", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryGreaterThan(String value) {
            addCriterion("cust_industry >", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryGreaterThanOrEqualTo(String value) {
            addCriterion("cust_industry >=", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryLessThan(String value) {
            addCriterion("cust_industry <", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryLessThanOrEqualTo(String value) {
            addCriterion("cust_industry <=", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryLike(String value) {
            addCriterion("cust_industry like", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryNotLike(String value) {
            addCriterion("cust_industry not like", value, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryIn(List<String> values) {
            addCriterion("cust_industry in", values, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryNotIn(List<String> values) {
            addCriterion("cust_industry not in", values, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryBetween(String value1, String value2) {
            addCriterion("cust_industry between", value1, value2, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustIndustryNotBetween(String value1, String value2) {
            addCriterion("cust_industry not between", value1, value2, "custIndustry");
            return (Criteria) this;
        }

        public Criteria andCustLevelIsNull() {
            addCriterion("cust_level is null");
            return (Criteria) this;
        }

        public Criteria andCustLevelIsNotNull() {
            addCriterion("cust_level is not null");
            return (Criteria) this;
        }

        public Criteria andCustLevelEqualTo(String value) {
            addCriterion("cust_level =", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelNotEqualTo(String value) {
            addCriterion("cust_level <>", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelGreaterThan(String value) {
            addCriterion("cust_level >", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelGreaterThanOrEqualTo(String value) {
            addCriterion("cust_level >=", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelLessThan(String value) {
            addCriterion("cust_level <", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelLessThanOrEqualTo(String value) {
            addCriterion("cust_level <=", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelLike(String value) {
            addCriterion("cust_level like", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelNotLike(String value) {
            addCriterion("cust_level not like", value, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelIn(List<String> values) {
            addCriterion("cust_level in", values, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelNotIn(List<String> values) {
            addCriterion("cust_level not in", values, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelBetween(String value1, String value2) {
            addCriterion("cust_level between", value1, value2, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLevelNotBetween(String value1, String value2) {
            addCriterion("cust_level not between", value1, value2, "custLevel");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanIsNull() {
            addCriterion("cust_linkman is null");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanIsNotNull() {
            addCriterion("cust_linkman is not null");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanEqualTo(String value) {
            addCriterion("cust_linkman =", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanNotEqualTo(String value) {
            addCriterion("cust_linkman <>", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanGreaterThan(String value) {
            addCriterion("cust_linkman >", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanGreaterThanOrEqualTo(String value) {
            addCriterion("cust_linkman >=", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanLessThan(String value) {
            addCriterion("cust_linkman <", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanLessThanOrEqualTo(String value) {
            addCriterion("cust_linkman <=", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanLike(String value) {
            addCriterion("cust_linkman like", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanNotLike(String value) {
            addCriterion("cust_linkman not like", value, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanIn(List<String> values) {
            addCriterion("cust_linkman in", values, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanNotIn(List<String> values) {
            addCriterion("cust_linkman not in", values, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanBetween(String value1, String value2) {
            addCriterion("cust_linkman between", value1, value2, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustLinkmanNotBetween(String value1, String value2) {
            addCriterion("cust_linkman not between", value1, value2, "custLinkman");
            return (Criteria) this;
        }

        public Criteria andCustPhoneIsNull() {
            addCriterion("cust_phone is null");
            return (Criteria) this;
        }

        public Criteria andCustPhoneIsNotNull() {
            addCriterion("cust_phone is not null");
            return (Criteria) this;
        }

        public Criteria andCustPhoneEqualTo(String value) {
            addCriterion("cust_phone =", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneNotEqualTo(String value) {
            addCriterion("cust_phone <>", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneGreaterThan(String value) {
            addCriterion("cust_phone >", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneGreaterThanOrEqualTo(String value) {
            addCriterion("cust_phone >=", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneLessThan(String value) {
            addCriterion("cust_phone <", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneLessThanOrEqualTo(String value) {
            addCriterion("cust_phone <=", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneLike(String value) {
            addCriterion("cust_phone like", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneNotLike(String value) {
            addCriterion("cust_phone not like", value, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneIn(List<String> values) {
            addCriterion("cust_phone in", values, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneNotIn(List<String> values) {
            addCriterion("cust_phone not in", values, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneBetween(String value1, String value2) {
            addCriterion("cust_phone between", value1, value2, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustPhoneNotBetween(String value1, String value2) {
            addCriterion("cust_phone not between", value1, value2, "custPhone");
            return (Criteria) this;
        }

        public Criteria andCustMobileIsNull() {
            addCriterion("cust_mobile is null");
            return (Criteria) this;
        }

        public Criteria andCustMobileIsNotNull() {
            addCriterion("cust_mobile is not null");
            return (Criteria) this;
        }

        public Criteria andCustMobileEqualTo(String value) {
            addCriterion("cust_mobile =", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileNotEqualTo(String value) {
            addCriterion("cust_mobile <>", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileGreaterThan(String value) {
            addCriterion("cust_mobile >", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileGreaterThanOrEqualTo(String value) {
            addCriterion("cust_mobile >=", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileLessThan(String value) {
            addCriterion("cust_mobile <", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileLessThanOrEqualTo(String value) {
            addCriterion("cust_mobile <=", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileLike(String value) {
            addCriterion("cust_mobile like", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileNotLike(String value) {
            addCriterion("cust_mobile not like", value, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileIn(List<String> values) {
            addCriterion("cust_mobile in", values, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileNotIn(List<String> values) {
            addCriterion("cust_mobile not in", values, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileBetween(String value1, String value2) {
            addCriterion("cust_mobile between", value1, value2, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustMobileNotBetween(String value1, String value2) {
            addCriterion("cust_mobile not between", value1, value2, "custMobile");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeIsNull() {
            addCriterion("cust_zipcode is null");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeIsNotNull() {
            addCriterion("cust_zipcode is not null");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeEqualTo(String value) {
            addCriterion("cust_zipcode =", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeNotEqualTo(String value) {
            addCriterion("cust_zipcode <>", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeGreaterThan(String value) {
            addCriterion("cust_zipcode >", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeGreaterThanOrEqualTo(String value) {
            addCriterion("cust_zipcode >=", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeLessThan(String value) {
            addCriterion("cust_zipcode <", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeLessThanOrEqualTo(String value) {
            addCriterion("cust_zipcode <=", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeLike(String value) {
            addCriterion("cust_zipcode like", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeNotLike(String value) {
            addCriterion("cust_zipcode not like", value, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeIn(List<String> values) {
            addCriterion("cust_zipcode in", values, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeNotIn(List<String> values) {
            addCriterion("cust_zipcode not in", values, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeBetween(String value1, String value2) {
            addCriterion("cust_zipcode between", value1, value2, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustZipcodeNotBetween(String value1, String value2) {
            addCriterion("cust_zipcode not between", value1, value2, "custZipcode");
            return (Criteria) this;
        }

        public Criteria andCustAddressIsNull() {
            addCriterion("cust_address is null");
            return (Criteria) this;
        }

        public Criteria andCustAddressIsNotNull() {
            addCriterion("cust_address is not null");
            return (Criteria) this;
        }

        public Criteria andCustAddressEqualTo(String value) {
            addCriterion("cust_address =", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressNotEqualTo(String value) {
            addCriterion("cust_address <>", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressGreaterThan(String value) {
            addCriterion("cust_address >", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressGreaterThanOrEqualTo(String value) {
            addCriterion("cust_address >=", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressLessThan(String value) {
            addCriterion("cust_address <", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressLessThanOrEqualTo(String value) {
            addCriterion("cust_address <=", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressLike(String value) {
            addCriterion("cust_address like", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressNotLike(String value) {
            addCriterion("cust_address not like", value, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressIn(List<String> values) {
            addCriterion("cust_address in", values, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressNotIn(List<String> values) {
            addCriterion("cust_address not in", values, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressBetween(String value1, String value2) {
            addCriterion("cust_address between", value1, value2, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustAddressNotBetween(String value1, String value2) {
            addCriterion("cust_address not between", value1, value2, "custAddress");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeIsNull() {
            addCriterion("cust_createtime is null");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeIsNotNull() {
            addCriterion("cust_createtime is not null");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeEqualTo(Date value) {
            addCriterion("cust_createtime =", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeNotEqualTo(Date value) {
            addCriterion("cust_createtime <>", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeGreaterThan(Date value) {
            addCriterion("cust_createtime >", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeGreaterThanOrEqualTo(Date value) {
            addCriterion("cust_createtime >=", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeLessThan(Date value) {
            addCriterion("cust_createtime <", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeLessThanOrEqualTo(Date value) {
            addCriterion("cust_createtime <=", value, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeIn(List<Date> values) {
            addCriterion("cust_createtime in", values, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeNotIn(List<Date> values) {
            addCriterion("cust_createtime not in", values, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeBetween(Date value1, Date value2) {
            addCriterion("cust_createtime between", value1, value2, "custCreatetime");
            return (Criteria) this;
        }

        public Criteria andCustCreatetimeNotBetween(Date value1, Date value2) {
            addCriterion("cust_createtime not between", value1, value2, "custCreatetime");
            return (Criteria) this;
        }
    }

    public static class Criteria extends GeneratedCriteria {

        protected Criteria() {
            super();
        }
    }

    public static class Criterion {
        private String condition;

        private Object value;

        private Object secondValue;

        private boolean noValue;

        private boolean singleValue;

        private boolean betweenValue;

        private boolean listValue;

        private String typeHandler;

        public String getCondition() {
            return condition;
        }

        public Object getValue() {
            return value;
        }

        public Object getSecondValue() {
            return secondValue;
        }

        public boolean isNoValue() {
            return noValue;
        }

        public boolean isSingleValue() {
            return singleValue;
        }

        public boolean isBetweenValue() {
            return betweenValue;
        }

        public boolean isListValue() {
            return listValue;
        }

        public String getTypeHandler() {
            return typeHandler;
        }

        protected Criterion(String condition) {
            super();
            this.condition = condition;
            this.typeHandler = null;
            this.noValue = true;
        }

        protected Criterion(String condition, Object value, String typeHandler) {
            super();
            this.condition = condition;
            this.value = value;
            this.typeHandler = typeHandler;
            if (value instanceof List<?>) {
                this.listValue = true;
            } else {
                this.singleValue = true;
            }
        }

        protected Criterion(String condition, Object value) {
            this(condition, value, null);
        }

        protected Criterion(String condition, Object value, Object secondValue, String typeHandler) {
            super();
            this.condition = condition;
            this.value = value;
            this.secondValue = secondValue;
            this.typeHandler = typeHandler;
            this.betweenValue = true;
        }

        protected Criterion(String condition, Object value, Object secondValue) {
            this(condition, value, secondValue, null);
        }
    }
}