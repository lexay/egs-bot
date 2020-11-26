RATINGS = %(
  query productReviewsQuery($sku: String!) {
      OpenCritic {
        productReviews(sku: $sku) {
          id
          name
          openCriticScore
          reviewCount
          percentRecommended
          openCriticUrl
          award
          topReviews {
            publishedDate
            externalUrl
            snippet
            language
            score
            author
          ScoreFormat {
            id
            description
          }
          OutletId
          outletName
          displayScore
                      }
        }
      }
    }
).freeze

MEDIA = %(
    query fetchMediaRef($mediaRefId: String!) {
      Media {
        getMediaRef(mediaRefId: $mediaRefId) {
          accountId
          outputs {
            duration
            url
            width
            height
            key
            contentType
          }
          namespace
        }
      }
    }
).freeze

CATALOG = %(
query catalogQuery($productNamespace: String!, $offerId: String!, $locale: String, $country: String!, $includeSubItems: Boolean!) {
  Catalog {
    catalogOffer(namespace: $productNamespace, id: $offerId, locale: $locale) {
      title
      id
      namespace
      description
      effectiveDate
      expiryDate
      isCodeRedemptionOnly
      keyImages {
        type
        url
      }
      seller {
        id
        name
      }
      productSlug
      urlSlug
      url
      tags {
        id
      }
      items {
        id
        namespace
      }
      customAttributes {
        key
        value
      }
      categories {
        path
      }
      price(country: $country) {
        totalPrice {
          discountPrice
          originalPrice
          voucherDiscount
          discount
          currencyCode
          currencyInfo {
            decimals
          }
          fmtPrice(locale: $locale) {
            originalPrice
            discountPrice
            intermediatePrice
          }
        }
        lineOffers {
          appliedRules {
            id
            endDate
            discountSetting {
              discountType
            }
          }
        }
      }
    }
    offerSubItems(namespace: $productNamespace, id: $offerId) @include(if: $includeSubItems) {
      namespace
      id
      releaseInfo {
        appId
        platform
      }
    }
  }
}
).freeze

DLC = %(
query getAddonsByNamespace($categories: String!, $count: Int!, $country: String!, $locale: String!, $namespace: String!, $sortBy: String!, $sortDir: String!) {
  Catalog {
    catalogOffers(namespace: $namespace, locale: $locale, params: {category: $categories, count: $count, country: $country, sortBy: $sortBy, sortDir: $sortDir}) {
      elements {
        countriesBlacklist
        customAttributes {
          key
          value
        }
        description
        developer
        effectiveDate
        id
        isFeatured
        keyImages {
          type
          url
        }
        price(country: $country) {
          totalPrice {
            discountPrice
            originalPrice
            voucherDiscount
            discount
            currencyCode
            currencyInfo {
              decimals
            }
            fmtPrice(locale: $locale) {
              originalPrice
              discountPrice
              intermediatePrice
            }
          }
          lineOffers {
            appliedRules {
              id
              endDate
              discountSetting {
                discountType
              }
            }
          }
        }
        lastModifiedDate
        longDescription
        namespace
        offerType
        productSlug
        releaseDate
        status
        technicalDetails
        title
        urlSlug
      }
    }
  }
}
).freeze
